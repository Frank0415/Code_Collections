obj-m := dice_module.o

dice_module-objs := dice.o dice_regular.o dice_backgammon.o dice_generic.o

KDIR ?= /lib/modules/$(shell uname -r)/build
PWD := $(shell pwd)

CC := clang

all:
	$(MAKE) -C $(KDIR) M=$(PWD) modules CC=$(CC)

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean
