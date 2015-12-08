Lab 6: File Systems
===================


Question 1: EXT4
----------------

In this part we investigate the current eMMC card file systems. On the Odroid, we can use the ``mount`` command to list the used (*"mounted"*) partitions::

    # mount
    rootfs on / type rootfs (rw)
    /dev/root on / type ext4 (rw,relatime,errors=remount-ro,data=ordered)
    devtmpfs on /dev type devtmpfs (rw,relatime,size=765332k,nr_inodes=121035,mode=755)
    proc on /proc type proc (rw,relatime)
    devpts on /dev/pts type devpts (rw,relatime,gid=5,mode=620)
    tmpfs on /dev/shm type tmpfs (rw,relatime,mode=777)
    tmpfs on /tmp type tmpfs (rw,relatime)
    sysfs on /sys type sysfs (rw,relatime)

We will look at the following question:

 - What is the real name for the node file ``/dev/root``  ?
 - What are the major and minor number for the ``/dev/root`` node file  ?
 - How the kernel knows that the **rootfs** in in the second partition ?
 
 
1) Real name of ``/dev/root``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

To know the real name of ``/dev/root`` we can use the ``ls`` command to see what kind of file it is (could be a node or a sym-link):: 

    # ls -l /dev/root
    lrwxrwxrwx    1 root     root             9 Jan  1 00:00 /dev/root -> mmcblk0p2
    
We can see here that this file is a sym-link to ``mmcblk0p2``. We can interpret this file name as "MMC block 0 , partition 2.


2) Major and minor number of the node file
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Again, the ``ls`` command commes to our resque to find the major and minor numbers::

    # ls -l /dev/mmcblk0p2
    brw-rw----    1 root     root      179,   2 Jan  1 00:00 /dev/mmcblk0p2
    
So we can see that for our *root file system* the **major** and **minor** numbers are **179** and **2**.


3) How the kernel knows where is the *rootfs*
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The kernel knows it beacause it was given as parameter at boot time by the boot-loader. This is given by the ``root`` argument on the command line. For the current setup this argument was set to ``/dev/mmcblk0p2``. We can see that is the same node file that is pointed by the symlink ``/dev/root``. 

This was set in lab2: U-Boot, question 3.


Question 2: Mount EXT4 "usr" partition
--------------------------------------


We are asked to manually mount the "usr" partition and then to add it to ``/etc/fstab`` to have it mounted automatically at startup. The **"usrfs"** is in the third partition represented by the node file ``/dev/mmcblk0p3``.

To mount is manually, we use the following commands::

    # mount -t ext4 -o defaults,noatime,discard,nodiratime,data=writeback,acl,user_xattr /dev/mmcblk0p3 /mnt/usrfs
    [ 2182.132281] [c4] EXT4-fs (mmcblk0p3): mounting with "discard" option, but the device dod
    [ 2182.140812] [c4] EXT4-fs (mmcblk0p3): mounted filesystem with writeback data mode. Optsr
    
    
To have it mounted at startup, we modify the ``/etc/fstab`` as following (last line added)::

                                                          
    # /etc/fstab: static file system information.                           
    #                                                                       
    # <file system> <mount pt>     <type>   <options>         <dump> <pass> 
    /dev/root       /              ext2     rw,noauto         0      1      
    proc            /proc          proc     defaults          0      0      
    devpts          /dev/pts       devpts   defaults,gid=5,mode=620   0    0
    tmpfs           /dev/shm       tmpfs    mode=0777         0      0      
    tmpfs           /tmp           tmpfs    mode=1777         0      0      
    sysfs           /sys           sysfs    defaults          0      0      
    /dev/mmcblk0p3  /mnt/usrfs     ext4     defaults,noatime,nodiratime,datawriteback,acl,user_xattr 0 0
    
We also need to create the mounting point directory::

    # mkdir /mnt/usrfs
    
The *"<dump>"* column is related to backup, we don't use it here so we can left it to "0". The *"<pass>"* column setup the file system check. Here we set that it should be checked after the root-fs, so we set it to valute "2" (zero would mean check is diabled).

After a reboot, we can see that the file system is mounted (last line)::

    # mount
    rootfs on / type rootfs (rw)
    /dev/root on / type ext4 (rw,relatime,errors=remount-ro,data=ordered)
    devtmpfs on /dev type devtmpfs (rw,relatime,size=765332k,nr_inodes=121035,mode=755)
    proc on /proc type proc (rw,relatime)
    devpts on /dev/pts type devpts (rw,relatime,gid=5,mode=620)
    tmpfs on /dev/shm type tmpfs (rw,relatime,mode=777)
    tmpfs on /tmp type tmpfs (rw,relatime)
    sysfs on /sys type sysfs (rw,relatime)
    /dev/mmcblk0p3 on /mnt/usrfs type ext4 (rw,noatime,nodiratime,data=writeback)




Question 3: EXT4 journaling
---------------------------


We are asked to check the write & read performances on a small and a big file with journaling enabled or disabled. 

To write those files, we can use the ``dd`` command:

    # To write a big files (100MB)
    dd if=/dev/zero of=test_file bs=1M count=100
    # To write a small file(5120kB)
    dd if=/dev/zero of=test_file bs=1k count=512    
    
We can then use the ``time``command to measure the time it take. 

We can then disable the EXT4 journaling and measure the time for a big and small file::

    # tune2fs -O ^has_journal /dev/mmcblk0p3




