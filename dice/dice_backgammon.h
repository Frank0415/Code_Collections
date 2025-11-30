#ifndef DICE_BACKGAMMON_H
#define DICE_BACKGAMMON_H

#include <linux/cdev.h>
#include <linux/mutex.h>

#define BACKGAMMON_DICE_SIDECOUNT 6
#define BACKGAMMON_DICE_COUNT 2

struct backgammon_dice_device
{
  struct cdev cdev;
  struct mutex mutex;
  int dice_count;
  int* dice_values;
};

int backgammon_dice_open(struct inode* inode, struct file* file);
int backgammon_dice_release(struct inode* inode, struct file* file);
long backgammon_dice_read(struct file* file, char __user* buffer, size_t count, loff_t* offset);
long backgammon_dice_write(struct file* file,
                           const char __user* buffer,
                           size_t count,
                           loff_t* offset);

static struct file_operations backgammon_dice_fops = {
    .owner = THIS_MODULE,
    .open = backgammon_dice_open,
    .release = backgammon_dice_release,
    .read = backgammon_dice_read,
    .write = backgammon_dice_write,
};

#endif // DICE_BACKGAMMON_H