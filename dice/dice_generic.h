#ifndef DICE_GENERIC_H
#define DICE_GENERIC_H

#include <linux/cdev.h>
#include <linux/mutex.h>

struct generic_dice_device
{
  int side_count;
  struct cdev cdev;
  struct mutex mutex;
  int dice_count;
  int* dice_values;
};

int generic_dice_open(struct inode* inode, struct file* file);
int generic_dice_release(struct inode* inode, struct file* file);
long generic_dice_read(struct file* file, char __user* buffer, size_t count, loff_t* offset);
long generic_dice_write(struct file* file, const char __user* buffer, size_t count, loff_t* offset);

static struct file_operations generic_dice_fops = {
    .owner = THIS_MODULE,
    .open = generic_dice_open,
    .release = generic_dice_release,
    .read = generic_dice_read,
    .write = generic_dice_write,
};

#endif // DICE_GENERIC_H