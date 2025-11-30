#include "dice_generic.h"
#include "dice_constants.h"
#include <linux/kernel.h>

static void
roll_dice(char* output_buffer, int* total_len, int dice_count, int* dice_values, int side_count);

int generic_dice_open(struct inode* inode, struct file* file)
{
  struct generic_dice_device* dev;
  dev = container_of(inode->i_cdev, struct generic_dice_device, cdev);
  file->private_data = dev;

  printk(KERN_INFO "Generic dice device opened\n");
  return 0;
}

int generic_dice_release(struct inode* inode, struct file* file)
{
  printk(KERN_INFO "Generic dice device closed\n");
  return 0;
}

// set dice when read, print to the buffer
long generic_dice_read(struct file* file, char __user* buffer, size_t count, loff_t* offset)
{
  struct generic_dice_device* dev = file->private_data;
  char* output_buffer;
  int total_len = 0;
  int ret;

  // has read some data
  if (*offset > 0)
  {
    return 0;
  }

  mutex_lock(&dev->mutex);

  output_buffer = kmalloc(PAGE_SIZE, GFP_KERNEL);
  if (!output_buffer)
  {
    mutex_unlock(&dev->mutex);
    return -ENOMEM;
  }

  roll_dice(output_buffer, &total_len, dev->dice_count, dev->dice_values, dev->side_count);

  if (count < total_len)
  {
    kfree(output_buffer);
    mutex_unlock(&dev->mutex);
    return -EINVAL;
  }
  ret = copy_to_user(buffer, output_buffer, total_len);
  kfree(output_buffer);
  mutex_unlock(&dev->mutex);
  if (ret)
  {
    return -EFAULT;
  }

  *offset = total_len;
  return total_len;
}

// set dice count and side count when writing into the file
long generic_dice_write(struct file* file, const char __user* buffer, size_t count, loff_t* offset)
{
  struct generic_dice_device* dev = file->private_data;
  char* input_buffer;
  int ret;

  if (*offset > 0)
  {
    return 0;
  }

  if (count > 32)
  {
    return -EINVAL;
  }

  mutex_lock(&dev->mutex);

  input_buffer = kmalloc(count + 1, GFP_KERNEL);
  if (!input_buffer)
  {
    mutex_unlock(&dev->mutex);
    return -ENOMEM;
  }

  ret = copy_from_user(input_buffer, buffer, count);
  if (ret)
  {
    kfree(input_buffer);
    mutex_unlock(&dev->mutex);
    return -EFAULT;
  }

  input_buffer[count] = '\0'; // Null-terminate the string

  ret = kstrtoint(input_buffer, 10, &dev->dice_count);
  if (ret)
  {
    kfree(input_buffer);
    mutex_unlock(&dev->mutex);
    return -EINVAL;
  }

  kfree(input_buffer);
  mutex_unlock(&dev->mutex);

  return count;
}

static void
roll_dice(char* output_buffer, int* total_len, int dice_count, int* dice_values, int side_count)
{
  if (dice_count < 1 || dice_count > MAX_DICE_COUNT)
  {
    *total_len += sprintf(output_buffer + *total_len, "Invalid dice count\n");
    return;
  }
  for (int i = 0; i < dice_count; i++)
  {
    dice_values[i] = get_random_u32() % side_count + 1;
  }

  for (int i = 0; i < dice_count; i++)
  {
    *total_len += sprintf(output_buffer + *total_len, "Dice%d: %d   ", i + 1, dice_values[i]);
  }

  *total_len += sprintf(output_buffer + *total_len, "\n");
}
