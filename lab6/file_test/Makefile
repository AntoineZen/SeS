TOOLCHAIN       = ~/workspace/xu3/buildroot/output/host/opt/ext-toolchain/bin
CROSS_COMPILE   = arm-linux-gnueabihf-
GCC             = $(TOOLCHAIN)/$(CROSS_COMPILE)gcc
OBJDUMP         = $(TOOLCHAIN)/$(CROSS_COMPILE)objdump
CFLAGS          = -fstack-protector-all


all: small_write big_write

small_write: small_write.c
	$(GCC) $(CFLAGS) -o $@ $<

big_write: big_write.c
	$(GCC) $(CFLAGS) -o $@ $<


.PHONY: clean

clean:
	rm small_write big_write
    
