TOOLCHAIN       = ~/workspace/xu3/buildroot/output/host/opt/ext-toolchain/bin
CROSS_COMPILE   = arm-linux-gnueabihf-
GCC             = $(TOOLCHAIN)/$(CROSS_COMPILE)gcc
OBJDUMP         = $(TOOLCHAIN)/$(CROSS_COMPILE)objdump
CFLAGS          = -fstack-protector-all


all: decompile_canary decompile_normal
normal_prog: canary_prog.c
	$(GCC) -o $@ $<

canary_prog: canary_prog.c
	$(GCC) $(CFLAGS) -o $@ $<


decompile_canary: canary_prog
	$(OBJDUMP) -d $< > canary_prog.txt 

decompile_normal: normal_prog
	$(OBJDUMP) -d $< > normal_prog.txt 



    
