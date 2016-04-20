
Lab 2: U-Boot
=============

Question 1: Check different mapping
-----------------------------------

In this question, we check what appends if we move the different parts that are copied to the
eMMC card that is used as boot media.
For each configuration, a script has been written to test the case. Each script is a modified version of
the original installation script. Please find them in annexe to this documents.

Here after are the result when we move the different parts:

 - Move of bl1.bin (see *1_shift_bl1.sh*): System does not boot, no print out on serial console.
 - Move of bl2.bin (see *1_shift_bl2.sh*): Same Result.
 - Move of u-boot (see *1_shift_u-boot.sh*): System does not boot, no print out on serial console, but fan in running.
 - Move of tzwf (see *1_shift_tzws.sh*): Same Result.
 - Move of uImage (see *1_shift_uImage.sh*): The u-boot can not find the kernel: ::

	U-Boot 2012.07 (Sep 16 2015 - 10:15:20) for Exynos5422

	CPU: Exynos5422 Rev0.1 [Samsung SOC on SMP Platform Base on ARM CortexA7]
	APLL = 800MHz, KPLL = 800MHz
	MPLL = 532MHz, BPLL = 825MHz

	Board: HardKernel ODROID
	DRAM:  2 GiB
	WARNING: Caches not enabled

	TrustZone Enabled BSP
	BL1 version:
	VDD_KFC: 0x44
	LDO19: 0xf2

	Checking Boot Mode ... SDMMC
	MMC:   S5P_MSHC2: 0, S5P_MSHC0: 1
	MMC Device 0: 7.4 GiB
	MMC Device 1: [ERROR] response error : 00000006 cmd 8
	[ERROR] response error : 00000006 cmd 55
	[ERROR] response error : 00000006 cmd 2
	*** Warning - bad CRC, using default environment

	In:    serial
	Out:   serial
	Err:   serial
	Net:   No ethernet found.
	Press 'Enter' or 'Space' to stop autoboot:  0 

	MMC read: dev # 0, block # 17647, count 256 ... there are pending interrupts 0x00000001
	256 blocks read: OK

	MMC read: dev # 0, block # 1263, count 16384 ... 16384 blocks read: OK
	Wrong Image Format for bootm command
	ERROR: can't get kernel image!
	ODROIDXU3> 

 - Move of the "Flattened Device Tree" (see *1_shift_device_tree.sh*): U-Boot complains that it can not find it: ::

 	U-Boot 2012.07 (Sep 16 2015 - 10:15:20) for Exynos5422

	CPU: Exynos5422 Rev0.1 [Samsung SOC on SMP Platform Base on ARM CortexA7]
	APLL = 800MHz, KPLL = 800MHz
	MPLL = 532MHz, BPLL = 825MHz

	Board: HardKernel ODROID
	DRAM:  2 GiB
	WARNING: Caches not enabled

	TrustZone Enabled BSP
	BL1 version: 
	VDD_KFC: 0x44
	LDO19: 0xf2

	Checking Boot Mode ... SDMMC
	MMC:   S5P_MSHC2: 0, S5P_MSHC0: 1
	MMC Device 0: 7.4 GiB
	MMC Device 1: [ERROR] response error : 00000006 cmd 8
	[ERROR] response error : 00000006 cmd 55
	[ERROR] response error : 00000006 cmd 2
	*** Warning - bad CRC, using default environment

	In:    serial
	Out:   serial
	Err:   serial
	Net:   No ethernet found.
	Press 'Enter' or 'Space' to stop autoboot:  0 

	MMC read: dev # 0, block # 17647, count 256 ... there are pending interrupts 0x00000001
	256 blocks read: OK

	MMC read: dev # 0, block # 1263, count 16384 ... 16384 blocks read: OK
	## Booting kernel from Legacy Image at 40007000 ...
	   Image Name:   Linux-3.10.63
	   Image Type:   ARM Linux Kernel Image (uncompressed)
	   Data Size:    3282576 Bytes = 3.1 MiB
	   Load Address: 40008000
	   Entry Point:  40008000
	   Verifying Checksum ... OK
	ERROR: Did not find a cmdline Flattened Device Tree
	Could not find a valid device tree
	ODROIDXU3> 


Question 2: Verify the kernel's checksum
----------------------------------------

In this question, we modify a byte inside the kernel compiled image. The goal
of this, is to check wetter or not *U-Boot* is able to detect it. If, it detect the
error, it should not boot the image.

Using the following command, we can modify the kernel image: ::

	$ cd ~/workspace/xu3/buildroot/output/images
	$ cp uImage uImage.orig
    $ hexedit uImage
    #   <modify some byte> Ctrl+x
	$ cd ~/master/SeS
	./0_base_sd_install.sh

Then U-Boot show the following error: ::

	U-Boot 2012.07 (Sep 16 2015 - 10:15:20) for Exynos5422

	CPU: Exynos5422 Rev0.1 [Samsung SOC on SMP Platform Base on ARM CortexA7]
	APLL = 800MHz, KPLL = 800MHz
	MPLL = 532MHz, BPLL = 825MHz

	Board: HardKernel ODROID
	DRAM:  2 GiB
	WARNING: Caches not enabled

	TrustZone Enabled BSP
	BL1 version: 
	VDD_KFC: 0x44
	LDO19: 0xf2

	Checking Boot Mode ... SDMMC
	MMC:   S5P_MSHC2: 0, S5P_MSHC0: 1
	MMC Device 0: 7.4 GiB
	MMC Device 1: [ERROR] response error : 00000006 cmd 8
	[ERROR] response error : 00000006 cmd 55
	[ERROR] response error : 00000006 cmd 2
	*** Warning - bad CRC, using default environment

	In:    serial
	Out:   serial
	Err:   serial
	Net:   No ethernet found.
	Press 'Enter' or 'Space' to stop autoboot:  0 

	MMC read: dev # 0, block # 17647, count 256 ... there are pending interrupts 0x00000001
	256 blocks read: OK

	MMC read: dev # 0, block # 1263, count 16384 ... 16384 blocks read: OK
	## Booting kernel from Legacy Image at 40007000 ...
	   Image Name:   Linux-3.10.63
	   Image Type:   ARM Linux Kernel Image (uncompressed)
	   Data Size:    3282576 Bytes = 3.1 MiB
	   Load Address: 40008000
	   Entry Point:  40008000
	   Verifying Checksum ... Bad Data CRC
	ERROR: can't get kernel image!


Question 3: Change The mapping
------------------------------

The goal of this question is to change the Image mapping of the eMMC card. We will now
have the kernel and the "Flattened device tree" in a partition instead having them in
the raw space before the root file-system. 

To archive this, modifiy lines 509:515 of file ``~/workspace/xu3/buildroot/output/build/uboot-eiafr-3/includes/configs/odroid.h`` ::

	"mmcboot="							\
		"run addttyargs addmmcargs addipargs; "			\
		"ext2load mmc 0:1 ${fdts_addr} exynos5422-odroidxu3.dtb; "		\
		"ext2load mmc 0:1 ${kernel_addr} uImage; "		\
		"bootm ${kernel_addr} - ${fdts_addr}\0"	

and line 494:495 (to tell that the rootfs is now second partition) : ::

	"addmmcargs=setenv bootargs ${bootargs} "			\
		"root=/dev/mmcblk0p2 rw rootwait rootfstype=ext4\0"	\

		



Then in ``~/workspace/xu3/buildroot/output/build/uboot-eiafr-3/`` do:  ::

	$ export ARCH=arm
	$ export CROSS_COMPILE=arm-linux-gnueabihf-
	$ export PATH=$PATH:~/workspace/xu3/buildroot/output/host/opt/ext-toolchain/bin
	$ make mrproper
	$ make odroid_config
	$ make
    $ cp u-boot.bin ../../images

Then we can use the script made on question 2 to build the eMMC image. The script is given in annexe 
and is called ``3_partition_sd_install.sh``.


Question 4 : Change network initialization
------------------------------------------

When the system boot, there is a timeout of 120s for the network to be ready. This is annoying and
we want to configure the network from the file-system instead of having it configured on the 
kernel's arguments. So we need to do the following actions:

 - Modify u-boot to not pass IP configuration to the kernel
 - Setup a network config file in the root-fs.

1) Modify the u-boot configuration in order u-boot don’t initialize the network
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

First, remove the IP options from the kernel arguments. For this modify again line 509:515 of ``~/workspace/xu3/buildroot/output/build/uboot-eiafr-3/includes/configs/odroid.h`` in this way: ::

	"mmcboot="							\
		"run addttyargs addmmcargs; "			        \
		"ext2load mmc 0:1 ${fdts_addr} exynos5422-odroidxu3.dtb; "		\
		"ext2load mmc 0:1 ${kernel_addr} uImage; "		\
		"bootm ${kernel_addr} - ${fdts_addr}\0"			\
	"erase_env=mmc erase user 0 0x4cf 0x20\0"

as this header file has been modified, we need to build u-boot again and copy it to the image folder ::

	$ make clean
	$ make
	$ cp u-boot.bin ../../images

2) Modify "/etc/network/interfaces"
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The ``/etc/network/interfaces`` file must look like this: ::

	# Configure Loop-back
	auto lo
	iface lo inet loopback

	# Configure Ethernet port 0
	auto eth0
	iface eth0 inet static
		address 192.168.0.11
		netmask 255.255.255.0
		gateway 192.168.0.4

3) Place the new configuration file in the root-fs
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

We want the ``/etc/network/interface`` to be included with the root-fs image to the correct place.
So we will add this to ``~/workspace/xu3/buildroot/system/skeleton/etc/network/interfaces``. Copy this file to the output folder
to avoid a clean. ::

 	$ cp ~/workspace/xu3/buildroot/system/skeleton/etc/network/interfaces ~/workspace/xu3/buildroot/output/target/etc/network/



4) Add new software to the root-fs
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

For the next laboratories, we need the following other package:

 - dhcp server
 - dhcp client
 - iw 
 - wpa-supplication
 - tune2fs (busybox applet)

To add the buildroot package, use "make menuconfig" and navigate to "Target Packages > Networking applications" and check "dhcp (ISC)", "dhcp server", "dhcp client", "iw" and "wpa-supplicant". Save and exit
To add the "tune2fs" busybox command use "make busybox-menuconfig". Naviagate to "Linux Ext2 FS Progs" and check "tune2fs". Save and exit.

5) Generate the new root-fs and install it on the eMMC
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Type "make" to update the image. Re install with the script created in Question 2 to write the images to the SD-Card.

After booting the Odroid, we can check that the commands are present using the "which" command: ::


	$ which dhcpd
	/usr/sbin/dhcpd

	$ which dhclient
	/usr/sbin/dhclient

	$ which iw
	/usr/sbin/iw

	$ which wpa_supplicant 
	/usr/sbin/wpa_supplicant

	$ which tune2fs
	/sbin/tunne2fs

Question 5: Add stack protection to u-boot.
-------------------------------------------

In this part, we take advantage of GCC's compilation that enables to improve the code security.

1) Modify u-boot's compilation option in order to improve the code security
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Modify ``~/workspace/xu3/buildroot/output/build/uboot-eiafr-3/config.mk`` at line 184:192 to the following: ::


	DBGFLAGS= -g # -DDEBUG
	OPTFLAGS= -Os  -fstack-protector-all #-fomit-frame-pointer

	OBJCFLAGS += --gap-fill=0xff

	gccincdir := $(shell $(CC) -print-file-name=include)

	CPPFLAGS :=  $(OPTFLAGS) $(RELFLAGS)		\
		-D__KERNEL__

On CPFLAGS, the inclusion of DBGFLAGS has been removed. On OPTFLAGS ``-fstack-protector-all`` has been added.

To compile the modified u-boot: ::

	$ make clean
	$ make

We can see that the -g options has been removed and the ``-fstack-protector-all`` has been added on the make output: ::

	arm-linux-gnueabihf-gcc  -Os  -fstack-protector-all   -fno-common -ffixed-r8 -mfloat-abi=hard -mfpu=vfpv3  -D__KERNEL__ -DCONFIG_SYS_TEXT_BASE=0x43E00000 -DCONFIG_SPL_TEXT_BASE=0x02027000 -I/home/antoine/workspace/xu3/buildroot/output/build/uboot-eiafr-3/include -fno-builtin -ffreestanding -nostdinc -isystem /home/antoine/workspace/xu3/buildroot/output/host/opt/ext-toolchain/bin/../lib/gcc/arm-linux-gnueabihf/4.9.2/include -pipe  -DCONFIG_ARM -D__ARM__ -marm -mno-thumb-interwork -mabi=aapcs-linux -march=armv7ve -mno-unaligned-access -Wall -Wstrict-prototypes -fno-stack-protector -Wno-format-nonliteral -Wno-format-security -fstack-usage -fno-toplevel-reorder     -o hello_world.o hello_world.c -c

after the build, copy the file to the output image folder ::

	$ cp u-boot.bin ../../images/

we can then rebuild the SD-Card using the script from question 2.

2) Write a small program on the PC to test the stack protection
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The following program was written: 

.. code-block:: c

	void bad_function()
	{
	    int i;
	    // Declare an array of 16 int on the stack.
	    int some_array[16];

	    // Overflow the array on the stack

	    for(i=0; i < 24; i++)
	    {
		some_array[i] = i;
	    }   
	}

	void good_function()
	{
	    int i;
	    // Declare an array of 16 int on the stack.
	    int some_array[16];

	    // Overflow the array on the stack

	    for(i=0; i < 16; i++)
	    {
		some_array[i] = i;
	    }   
	}

	int main()
	{
	    good_function();
	    bad_function();
	    return 0;
	}

A small makefile enable to compile it:

.. code-block:: makefile

	TOOLCHAIN       = ~/workspace/xu3/buildroot/output/host/opt/ext-toolchain/bin
	CROSS_COMPILE   = arm-linux-gnueabihf-
	GCC             = $(TOOLCHAIN)/$(CROSS_COMPILE)gcc
	CFLAGS          = -fstack-protector-all


	canary_prog: canary_prog.c
		$(GCC) $(CFLAGS) -o $@ $<

We can copy it to the *"usrfs"* of the SD-Card. After booting the Odroid, we can try to run it: ::

	# Mount the "usrfs" patition
	$ mount /dev/mmcblk0p2 /mnt
	$ cd /mnt
	$ ./canary_prog
	*** stack smashing detected ***: ./canary_prog terminated
	Aborted


by decompiling it and comparing with the same program compiled without the "-fstack-protector-all" options, we can see that the following code is added at enter of a function::

   10496:	f240 6398 	movw	r3, #1688	; 0x698
   1049a:	f2c0 0302 	movt	r3, #2
   1049e:	681b      	ldr	r3, [r3, #0]
   ... Rest of the function.
	
    

