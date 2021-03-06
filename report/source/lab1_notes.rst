
Lab 1: Odoid Buildroot installation
===================================

The setup of the *buildroot* project should be straight forward as given in the laboratory handout::

	# Create a dir to work in 

	$ mkdir ~/workspace
	$ cd ~/workspace

	# Checkout the required resources
	$ git clone -o upstream https://forge.tic.eia-fr.ch/git/es4-1415/xu3.git
	$ cd ~/workspace/xu3
	$ git  clone git://git.buildroot.net/buildroot
	$ cd buildroot git  checkout -b xu3 2014.11

	# Patch what is required for the lab to work
	$ patch -p1 < ~/workspace/xu3/scripts/config/buildroot-xu3.patch

	# Install root-fs creation script
	$ cp  ~/workspace/xu3/scripts/config/rootfs-ext.tar  board/hardkernel/xu3
	$ chmod +x board/hardkernel/xu3/post_image_creation.sh
	$ chmod +x board/hardkernel/xu3/pre_image_creation.sh

	# Build the images
	$ make odroidxu3_defconfig
	$ make

Unfortunately, this does not work on my machine. *Make* gives the following error: ::

	Cannot execute cross-compiler '/home/antoine/workspace/xu3/buildroot/output/host/opt/ext-toolchain/bin/arm-linux-gnueabihf-gcc'
	make: *** [/home/antoine/workspace/xu3/buildroot/output/build/toolchain-external-undefined/.stamp_configured] Error 1


if we try to call the compiler by hand, the error is then the following: ::

	antoine@antoine-vb-64:~/workspace/xu3/buildroot/output/host/opt/ext-toolchain/bin$ ./arm-linux-gnueabihf-gcc
	./arm-linux-gnueabihf-gcc: error while loading shared libraries: libstdc++.so.6: cannot open shared object file: No such file or directory


if we look for the shared libraries above, we can see that it is included in the following places, so there is no reason for gcc no to find id: ::

	$ sudo find / -name libstdc++.so.6
	[sudo] password for antoine: 
	/home/antoine/workspace/xu3/buildroot/output/host/opt/ext-toolchain/arm-linux-gnueabihf/lib/libstdc++.so.6
	/usr/lib/x86_64-linux-gnu/libstdc++.so.6

Looking at the given GCC, it appears to be 32 bits executable: ::

	antoine@antoine-vb-64:~/workspace/xu3/buildroot/output/host/opt/ext-toolchain/bin$ file arm-linux-gnueabihf-gcc-4.9.2 
	arm-linux-gnueabihf-gcc-4.9.2: ELF 32-bit LSB  executable, Intel 80386, version 1 (SYSV), dynamically linked (uses shared libs), for GNU/Linux 2.6.15, stripped

My machine is 64 bits: ::

	antoine@antoine-vb-64:~$ uname -a
	Linux antoine-vb-64 3.16.0-49-generic #65~14.04.1-Ubuntu SMP Wed Sep 9 10:03:23 UTC 2015 x86_64 x86_64 x86_64 GNU/Linux


So to solve this, we need to install the following 32 bits libraries:a ::

	sudo apt-get install lib32stdc++6 zlib1g:i386
