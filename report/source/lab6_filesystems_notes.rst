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
    /dev/mmcblk0p3  /mnt/usrfs     ext4     defaults,noatime,discard,nodiratime,data=writeback,acl,user_xattr 0 0
    
The file in ``buildroot/system/skeleton/etc`` could be modified as well to have those modifications persisting when making a new root file system.
    
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

To write those files, two small C program have been made. The first one writes a small file (it write 4 block of 2014 bytes = 4kBytes)::

    #include <stdio.h>
    #include <string.h>
    #include <stdlib.h>
    
    #define BLOCK_SIZE 1024
    
    main(int argc, char *argv[])
    {
        void* ptr;
        FILE* f = fopen("generated_file", "w");
        int i;
    
        for(i=0; i < 4; i++)
        {
            ptr = malloc(BLOCK_SIZE);
            memset(ptr, 0xAA, BLOCK_SIZE);
    
            fwrite(ptr, BLOCK_SIZE, 1, f);
    
            free(ptr);
        }
    
        fclose(f);
    }

And the one that writes a big file (it writes 40 block of 1Mbytes = 40Mbytes)::


    #include <stdio.h>
    #include <string.h>
    #include <stdlib.h>
    
    #define BLOCK_SIZE (1024*1024)
    
    main(int argc, char *argv[])
    {
        void* ptr;
        FILE* f = fopen("generated_file", "w");
        int i;
    
        for(i=0; i < 40; i++)
        {
            ptr = malloc(BLOCK_SIZE);
            memset(ptr, 0xAA, BLOCK_SIZE);
    
            fwrite(ptr, BLOCK_SIZE, 1, f);
    
            free(ptr);
        }
    
        fclose(f);
    }


We can then use the ``time``command to measure the time it take to run both programs::

    # time ./big_write
    Command exited with non-zero status 1
    real    0m 0.89s
    user    0m 0.01s
    sys     0m 0.88s
    # time ./small_write 
    Command exited with non-zero status 1
    real    0m 0.09s
    user    0m 0.00s
    sys     0m 0.09s


We can then disable the EXT4 journaling and measure the time for a big and small file::

    # cd
    # umount /mnt/usrfs/
    # tune2fs -O ^has_journal /dev/mmcblk0p3
    tune2fs 1.42.12 (29-Aug-2014)
    # mount /mnt/usrfs/
    [  844.419881] [c6] EXT4-fs (mmcblk0p3): mounting with "discard" option, but the device does not support discard
    [  844.428370] [c6] EXT4-fs (mmcblk0p3): mounted filesystem without journal. Opts: discard,data=writeback,acl,user_xattr
    
    
We can then repeat the measure::

    # time ./big_write
    Command exited with non-zero status 1
    real    0m 0.86s
    user    0m 0.00s
    sys     0m 0.73s
    # time ./small_write 
    Command exited with non-zero status 1
    real    0m 0.08s
    user    0m 0.00s
    sys     0m 0.08s


We can see that haveing the journaling disabled reduced the execution time of 30ms and 10ms.




Question 4: SQUASHFS
--------------------
    
We can prepare some data to make the SQUASHFS partition::

    # cd /mnt/usrfs
    # mkdir sqfs
    # cp -r /usr/* sqfs
    
    
Then we can create SQUASHFS files with different compressions::

    # mksquashfs sqfs/ part.gzip.sqsh -comp gzip
    # mksquashfs sqfs/ part.lz4.sqsh -comp lz4
    # mksquashfs sqfs/ part.lzma.sqsh -comp lzma
    # mksquashfs sqfs/ part.lzo.sqsh -comp lzo
    # mksquashfs sqfs/ part.xz.sqsh -comp xz
    

We can then compare the size of the files created with the various compressions algorithms::

    # ls -lh *.sqsh
    -rw-r--r--    1 root     root        7.0M Jan  1 00:06 part.gzip.sqsh
    -rw-r--r--    1 root     root       10.4M Jan  1 00:07 part.lz4.sqsh
    -rw-r--r--    1 root     root        5.6M Jan  1 00:06 part.lzma.sqsh
    -rw-r--r--    1 root     root        7.7M Jan  1 00:07 part.lzo.sqsh
    -rw-r--r--    1 root     root        5.6M Jan  1 00:08 part.xz.sqsh
    
    
This shows that **lzma** and **xz** algorithms offers the smallest sizes.


We can then mount any of those partion to the ``/mnt/sqfs`` mounting point (we need to create it first)::

    # cd /mnt
    # mkdir sqfs
    # mount -t squashfs -o loop /mnt/usrfs/part.gzip.sqsh /mnt/sqfs
    mount: mounting  on /mnt/sqfs failed: No such device

Note that the support for SQUASHFS must first be enabled in the kernel. In our case it was needed to re-compile a kernel with this support enable. We use ``make xconfig`` then searched for *SquashFS* and selected it. Then a simple ``make `` build the new kernel that should then flashed to the MMC card (or copied in the boot partition). 

**But still, I was not able to mount the partition using loopback on the odroid**


Question 4: SQUASHFS partition
------------------------------

On the pc, we can create a new partition on the eMMC card. This parition will start at 16MB (bootloader) + 64MB (bootfs) + 256MB (rootfs) + 256MB (usrfs) = 592MB.  This represent 1212416 sectors of 512 bytes. It will end at 848MB = sector 1736703. So now that we know the offset, we can create the partition::

    antoine@antoine-vb-64:~$ sudo parted /dev/sdb mkpart primary 1212416s 1736703s
    Information: You may need to update /etc/fstab.                           
    
    antoine@antoine-vb-64:~$ sudo fdisk -l /dev/sdb
    
    Disk /dev/sdb: 7948 MB, 7948206080 bytes
    245 heads, 62 sectors/track, 1021 cylinders, total 15523840 sectors
    Units = sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes
    Disk identifier: 0x000f2984
    
       Device Boot      Start         End      Blocks   Id  System
    /dev/sdb1           32768      163839       65536   83  Linux
    /dev/sdb2          163840      688127      262144   83  Linux
    /dev/sdb3          688128     1212415      262144   83  Linux
    /dev/sdb4         1212416     1736703      262144   83  Linux

We can the copy one squashfs file to the freshly created partition::

    antoine@antoine-vb-64:~$ sudo dd if=/media/antoine/usrfs/part.gzip.sqsh of=/dev/sdb4
    14424+0 records in
    14424+0 records out
    7385088 bytes (7.4 MB) copied, 7.5977 s, 972 kB/s

We can then mount it and check that it is really read-only::

    antoine@antoine-vb-64:~$ mkdir /mnt/sqfs
    antoine@antoine-vb-64:~$ sudo mount -t squashfs /dev/sdb4 /mnt/sqfs
    mount: warning: /mnt/sqfs seems to be mounted read-only.
    
    antoine@antoine-vb-64:/mnt/sqfs/bin$ mount | grep sdb4
    /dev/sdb4 on /mnt/sqfs type squashfs (ro)

    antoine@antoine-vb-64:~$ cd /mnt/sqfs/bin
    antoine@antoine-vb-64:/mnt/sqfs/bin$ ls
    [          dirname    killall  lzless      pkill        slabtop           top         wget
    [[         dos2unix   last     lzma        pmap         slogin            tr          which
    ar         du         less     lzmadec     printf       sort              traceroute  who
    awk        eject      logger   lzmainfo    pwdx         ssh               tty         whoami
    basename   env        logname  lzmore      readlink     ssh-add           uniq        xargs
    bunzip2    expr       lsattr   md5sum      realpath     ssh-agent         unix2dos    xz
    bzcat      find       lsof     mesg        renice       ssh-keygen        unlzma      xzcat
    chattr     fold       lspci    microcom    reset        ssh-keyscan       unsquashfs  xzcmp
    chrt       free       lsusb    mkfifo      resize       strace            unxz        xzdec
    chvt       fuser      lz4      mksquashfs  scp          strace-log-merge  unzip       xzdiff
    cksum      gdbserver  lz4c     nohup       seq          strings           uptime      xzegrep
    clear      head       lz4cat   nslookup    setkeycodes  tail              uudecode    xzfgrep
    cmp        hexdump    lzcat    od          setsid       tee               uuencode    xzgrep
    crontab    hostid     lzcmp    openvt      sftp         telnet            vlock       xzless
    cut        id         lzdiff   passwd      sha1sum      test              vmstat      xzmore
    dc         install    lzegrep  patch       sha256sum    tftp              w           yes
    deallocvt  ipcrm      lzfgrep  pgrep       sha3sum      time              watch
    diff       ipcs       lzgrep   pidof       sha512sum    tload             wc
    
    
    antoine@antoine-vb-64:/mnt/sqfs/bin$ rm watch 
    rm: cannot remove ‘watch’: Read-only file system


The file cannot be removed, this prof that the file system is read-only.
    



