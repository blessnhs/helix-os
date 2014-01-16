ARCH		= i586
TARGET		= $(ARCH)-elf
MAKE		= make
EMULATOR	= qemu-system-i386
EMU_FLAGS	= -hda helix.img -s -serial stdio -m 32 -nographic 
#EMU_FLAGS	= -kernel kernel/helix_kernel-i586 -serial stdio -nographic -m 16 -s
CROSS		= $(shell pwd)/cross

KNAME		= obsidian-$(ARCH)

NATIVECC	= gcc
CC		= $(CROSS)/bin/$(TARGET)-gcc
LD		= $(CROSS)/bin/$(TARGET)-ld
AS		= nasm
OBJCOPY		= $(CROSS)/bin/$(TARGET)-objcopy
STRIP		= $(CROSS)/bin/$(TARGET)-strip
CONFIG_C_FLAGS	= -g

all: helix-kernel ktools image
dev-all: check helix-kernel userland image docs test

debug:
	@gdb -x gdbscript

check:
	@if [ ! -e cross/.check-$(ARCH)-elf ]; then \
		echo "-----=[Note]=-----";\
		echo "It is recommended that you build a cross compiler using"; \
		echo "    \"$(MAKE) cross-cc\""; \
		echo "if you haven't done so already, for best results."; \
		echo;\
		echo "Your native compiler may work, but if it refuses to boot or compile,";\
		echo "try a cross compiler before assuming bugs. ;)";\
		echo;\
	fi

helix-kernel:
	@cd kernel; $(MAKE) KNAME=$(KNAME) CONFIG_C_FLAGS="$(CONFIG_C_FLAGS)" \
		  AS=$(AS) CC=$(CC) LD=$(LD) SPLIT=$(SPLIT) OBJCOPY=$(OBJCOPY) ARCH=$(ARCH)

ktools:
	cd tools; $(MAKE)

image:
	@echo -e "[\033[0;34mGenerating image...\033[0;0m]"
	@echo -e "[\033[0;32mMaking image\033[0;0m]"
	@# The order of the files in kernel/modules is important, the modules
	@# are loaded in this order
	@tools/mkinitrd ./initrd.img kernel/modules/{pci,ata,dummy}_mod.o
	@#tools/mkinitrd ./initrd.img kernel/modules/dummy_mod.o
	@./mk_image.sh
	@echo "To boot: $(EMULATOR) $(EMU_FLAGS)"
	@echo -e "[\033[0;32mdone\033[0;0m]"
	@echo -e "[\033[0;34mdone\033[0;0m]";

userland:
	@cd user; $(MAKE)

test:
	$(EMULATOR) $(EMU_FLAGS)

cross-cc:
	@echo -e "[\033[0;34mMaking cross-compiler...\033[0;0m]"
	@#cd cross; $(MAKE) MAKE=$(MAKE) TARGET=$(TARGET) -j $$(( `cat /proc/cpuinfo | grep "^proc" | wc -l` * 2 ))
	@cd cross; $(MAKE) MAKE=$(MAKE) TARGET=$(TARGET) 
	@echo -e "[\033[0;34mdone\033[0;0m]"

docs:
	@echo -e "[\033[0;34mMaking documentation...\033[0;0m]"
	@doxygen doc/doc.conf > /dev/null
	@echo -e "[\033[0;34mdone\033[0;0m]";

clean:
	@cd kernel; $(MAKE) clean
	@cd tools; $(MAKE) clean
	@-rm *.img

.PHONY: all

meh:
	tools/mkinitrd ./initrd.img kernel/modules/*
