#ifndef DICE_REGULAR_H
#define DICE_REGULAR_H

#include <linux/mutex.h>
#include <linux/cdev.h>

#define REGULAR_DICE_SIDECOUNT 6

struct regular_dice_device
{
  struct cdev cdev;
  struct mutex mutex;
  int dice_count;
  int* dice_values;
};

int regular_dice_open(struct inode* inode, struct file* file);
int regular_dice_release(struct inode* inode, struct file* file);
long regular_dice_read(struct file* file, char __user* buffer, size_t count, loff_t* offset);
long regular_dice_write(struct file* file, const char __user* buffer, size_t count, loff_t* offset);

static struct file_operations regular_dice_fops = {
    .owner = THIS_MODULE,
    .open = regular_dice_open,
    .release = regular_dice_release,
    .read = regular_dice_read,
    .write = regular_dice_write,
};



#endif // DICE_REGULAR_H