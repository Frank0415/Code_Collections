#include "dice_backgammon.h"
#include "dice_constants.h"
#include "dice_generic.h"
#include "dice_regular.h"
#include <linux/cdev.h>
#include <linux/fs.h>
#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/mutex.h>
#include <linux/random.h>

#define NUM_DEVICES 3

static int device_major;
static struct class* dice_class;
static struct regular_dice_device* regular_dev;
static struct regular_dice_device* backgammon_dev;
static struct generic_dice_device* generic_dev;

static int common_sides = 6;
module_param(common_sides, int, 0644);
MODULE_INFO(tag, "common");
MODULE_INFO(info, "Number of sides for common dice (default 6, range 1-100)");

static int __init dice_init(void)
{
  int ret;
  dev_t device_number;

  if (common_sides < 1 || common_sides > 100)
  {
    pr_err("Invalid sides value: %d (must be 1-100)\n", common_sides);
    return -EINVAL;
  }

  ret = alloc_chrdev_region(&device_number, 0, NUM_DEVICES, "dice");
  if (ret < 0)
  {
    printk(KERN_ERR "dice: failed to allocate major numbers\n");
    return ret;
  }

  device_major = MAJOR(device_number);

  dice_class = class_create("dice_class");
  if (IS_ERR(dice_class))
  {
    printk(KERN_ERR "dice: failed to create class\n");
    ret = PTR_ERR(dice_class);
    goto unregister_chrdev;
  }

  // Regular dice device (dice0)
  regular_dev = kmalloc(sizeof(struct regular_dice_device), GFP_KERNEL);
  if (!regular_dev)
  {
    ret = -ENOMEM;
    goto destroy_class;
  }
  regular_dev->dice_values = kmalloc_array(MAX_DICE_COUNT, sizeof(int), GFP_KERNEL);
  if (!regular_dev->dice_values)
  {
    ret = -ENOMEM;
    goto free_regular_dev;
  }
  regular_dev->dice_count = 1;
  mutex_init(&regular_dev->mutex);
  cdev_init(&regular_dev->cdev, &regular_dice_fops);
  regular_dev->cdev.owner = THIS_MODULE;
  ret = cdev_add(&regular_dev->cdev, MKDEV(device_major, 0), 1);
  if (ret)
  {
    goto free_regular_values;
  }
  if (IS_ERR(device_create(dice_class, NULL, MKDEV(device_major, 0), NULL, "dice%d", 0)))
  {
    printk(KERN_ERR "dice: failed to create device dice0\n");
    goto destroy_regular_cdev;
  }

  // Backgammon dice device (dice1)
  backgammon_dev = kmalloc(sizeof(struct regular_dice_device), GFP_KERNEL);
  if (!backgammon_dev)
  {
    ret = -ENOMEM;
    goto destroy_regular_device;
  }
  backgammon_dev->dice_values = kmalloc_array(BACKGAMMON_DICE_COUNT * MAX_DICE_COUNT, sizeof(int), GFP_KERNEL);
  if (!backgammon_dev->dice_values)
  {
    ret = -ENOMEM;
    goto free_backgammon_dev;
  }
  backgammon_dev->dice_count = 2;
  mutex_init(&backgammon_dev->mutex);
  cdev_init(&backgammon_dev->cdev, &backgammon_dice_fops);
  backgammon_dev->cdev.owner = THIS_MODULE;
  ret = cdev_add(&backgammon_dev->cdev, MKDEV(device_major, 1), 1);
  if (ret)
  {
    goto free_backgammon_values;
  }
  if (IS_ERR(device_create(dice_class, NULL, MKDEV(device_major, 1), NULL, "dice%d", 1)))
  {
    printk(KERN_ERR "dice: failed to create device dice1\n");
    goto destroy_backgammon_cdev;
  }

  // Generic dice device (dice2)
  generic_dev = kmalloc(sizeof(struct generic_dice_device), GFP_KERNEL);
  if (!generic_dev)
  {
    ret = -ENOMEM;
    goto destroy_backgammon_device;
  }
  generic_dev->dice_values = kmalloc_array(MAX_DICE_COUNT, sizeof(int), GFP_KERNEL);
  if (!generic_dev->dice_values)
  {
    ret = -ENOMEM;
    goto free_generic_dev;
  }
  generic_dev->dice_count = 1;
  generic_dev->side_count = common_sides;
  mutex_init(&generic_dev->mutex);
  cdev_init(&generic_dev->cdev, &generic_dice_fops);
  generic_dev->cdev.owner = THIS_MODULE;
  ret = cdev_add(&generic_dev->cdev, MKDEV(device_major, 2), 1);
  if (ret)
  {
    goto free_generic_values;
  }
  if (IS_ERR(device_create(dice_class, NULL, MKDEV(device_major, 2), NULL, "dice%d", 2)))
  {
    printk(KERN_ERR "dice: failed to create device dice2\n");
    goto destroy_generic_cdev;
  }

  ret = printk(KERN_INFO "dice: module loaded with %d devices\n", NUM_DEVICES);
  return 0;

destroy_generic_cdev:
  cdev_del(&generic_dev->cdev);
free_generic_values:
  kfree(generic_dev->dice_values);
free_generic_dev:
  kfree(generic_dev);
destroy_backgammon_device:
  device_destroy(dice_class, MKDEV(device_major, 1));
destroy_backgammon_cdev:
  cdev_del(&backgammon_dev->cdev);
free_backgammon_values:
  kfree(backgammon_dev->dice_values);
free_backgammon_dev:
  kfree(backgammon_dev);
destroy_regular_device:
  device_destroy(dice_class, MKDEV(device_major, 0));
destroy_regular_cdev:
  cdev_del(&regular_dev->cdev);
free_regular_values:
  kfree(regular_dev->dice_values);
free_regular_dev:
  kfree(regular_dev);
destroy_class:
  class_destroy(dice_class);
unregister_chrdev:
  unregister_chrdev_region(device_number, NUM_DEVICES);
  return ret;
}

static void __exit dice_exit(void)
{
  device_destroy(dice_class, MKDEV(device_major, 2));
  cdev_del(&generic_dev->cdev);
  kfree(generic_dev->dice_values);
  kfree(generic_dev);

  device_destroy(dice_class, MKDEV(device_major, 1));
  cdev_del(&backgammon_dev->cdev);
  kfree(backgammon_dev->dice_values);
  kfree(backgammon_dev);

  device_destroy(dice_class, MKDEV(device_major, 0));
  cdev_del(&regular_dev->cdev);
  kfree(regular_dev->dice_values);
  kfree(regular_dev);

  class_destroy(dice_class);
  unregister_chrdev_region(MKDEV(device_major, 0), NUM_DEVICES);
  printk(KERN_INFO "dice: module unloaded\n");
}
module_init(dice_init);
module_exit(dice_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Yuzhao Shi");
MODULE_DESCRIPTION("Dice rolling Kernel Device Module");
MODULE_VERSION("1.0");