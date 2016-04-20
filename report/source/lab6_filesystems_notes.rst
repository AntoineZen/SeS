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


We can then use the ``time`` command to measure the time it take to run both programs::

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

Note that the support for SQUASHFS must first be enabled in the kernel. In our case it was needed to re-compile a kernel with this support enable. We use ``make xconfig`` then searched for *SquashFS* and selected it. Then a simple ``make`` build the new kernel that should then flashed to the MMC card (or copied in the boot partition). 

**But still, I was not able to mount the partition using loopback on the odroid**


Question 5: SQUASHFS partition
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


Question 6.1: LUKS, cryptsetup, dmcrypt
---------------------------------------

We need to add dmcrypt support in the kernel for this, we use the menu configuration:

    # cd ~/workspace/xu3/buildroot
    # make linux-xconfig
    
Then we need to select the "Crypt target Support". To find it, the easier it to search (CTRL+F) for ``dm_crypt`` and to check the option. Do not forget to save before closing the congiuration.

Then we must confiurue buildroot to comptyte cryptsetup::

    # make xconfig
    
To find the option, to easier is to search (CTRL+F) for ``cryptsetup``. Select it, save the configuraiton and close. Then we can recompile the buildroot environement (it will compile what needed)::

    # make
    
    
We made a new script that just copy the rootfs and the kernel into the bootfs partition::

    #!/bin/bash
    
    TARGET_VOLUME=sdb
    IMAGEDIR="/home/antoine/workspace/xu3/buildroot/output/images"
    
    echo "Target volume is ${TARGET_VOLUME}"
    echo "Image dir is ${IMAGEDIR}"
    
    # Show patition table
    echo "Patition table is"
    sudo fdisk -l /dev/${TARGET_VOLUME} 
    
    sleep 3
    
    if [ -e "/dev/${TARGET_VOLUME}1" ]
    then
    	umount /dev/${TARGET_VOLUME}1
    fi
    if [ -e "/dev/${TARGET_VOLUME}2" ]
    then
    	umount /dev/${TARGET_VOLUME}2
    fi
    if [ -e "/dev/${TARGET_VOLUME}3" ]
    then
    	umount /dev/${TARGET_VOLUME}3
    fi
    if [ -e "/dev/${TARGET_VOLUME}4" ]
    then
    	umount /dev/${TARGET_VOLUME}4
    fi
    
    
    #copy rootfs
    echo "Copy rootfs"
    sudo dd if=${IMAGEDIR}/rootfs.ext4 of=/dev/${TARGET_VOLUME} bs=512 seek=163840
    
    #copy kernel
    sudo mount /dev/${TARGET_VOLUME}1 /mnt
    echo "Copy kernel"
    sudo cp ${IMAGEDIR}/uImage /mnt/
    
    
    sudo umount /dev/${TARGET_VOLUME}1
    
    # Show patition table
    echo "Patition table is"
    sudo fdisk -l /dev/${TARGET_VOLUME}
    

Question 6.2 : LUKS, cryptsetup option
--------------------------------------

LUKS extension mode of cyrptsetup has the advantage of being standard, to manage multiple password and to be protected against dictionary attacks.

The ``--hash`` options specify the has funtion to use on LUKS partition creation. On the Odroid, only *sha1* is supported (according to *crytpsetup --help*).

The default cypher (according to *crytpsetup --help*) for KUKS partition is **"aes-xts-plain64"**.

The ``--key-file`` option specify the file storing the key.


Question 6.3 : LUKS test 1
--------------------------

In this part we test LUKS on the usrfs partition. First, on the odroid, we create initialize the LUKS partition (we need to un-mount the partition first) ::
    
    
    # umount /mnt/usrfs/

    # cryptsetup --debug luksFormat /dev/mmcblk0p3
    # cryptsetup 1.6.6 processing "cryptsetup --debug luksFormat /dev/mmcblk0p3"
    # Running command luksFormat.
    # Locking memory.
    # Installing SIGINT/SIGTERM handler.
    # Unblocking interruption on signal.
    
    WARNING!
    ========
    This will overwrite data on /dev/mmcblk0p3 irrevocably.
    
    Are you sure? (Type uppercase yes): YES
    # Allocating crypt device /dev/mmcblk0p3 context.
    # Trying to open and read device /dev/mmcblk0p3.
    # Initialising device-mapper backend library.
    # Timeout set to 0 miliseconds.
    # Iteration time set to 1000 miliseconds.
    # Interactive passphrase entry requested.
    Enter passphrase: 
    Verify passphrase: 
    # Formatting device /dev/mmcblk0p3 as type LUKS1.
    # Crypto backend (gcrypt 1.6.2) initialized.
    # Detected kernel Linux 3.10.63 armv7l.
    # Topology: IO (512/0), offset = 0; Required alignment is 1048576 bytes.
    # Checking if cipher aes-xts-plain64 is usable.
    # Users[ 1041.701148] [c3] bio: create slab <bio-1> at 1
    pace crypto wrapper cannot use aes-xts-plain64 (-95).
    # Using dmcrypt to access keyslot area.
    # Calculated device size is 1 sectors (RW), offset 0.
    # dm version   OF   [16384] (*1)
    # dm versions   OF   [16384] (*1)
    # Detected dm-crypt version 1.12.1, dm-ioctl version 4.24.0.
    # Device-mapper backend running with UDEV support disabled.
    # DM-UUID is CRYPT-TEMP-temporary-cryptsetup-1671
    # dm create temporary-cryptsetup-1671 CRYPT-TEMP-temporary-cryptsetup-1671 OF   [16384] (*1)
    # dm reload temporary-cryptsetup-1671  OFRW    [16384] (*1)
    # dm resume temporary-cryptsetup-1671  OFRW    [16384] (*1)
    # temporary-cryptsetup-1671: Stacking NODE_ADD (254,0) 0:0 0600
    # temporary-cryptsetup-1671: Stacking NODE_READ_AHEAD 256 (flags=1)
    # temporary-cryptsetup-1671: Processing NODE_ADD (254,0) 0:0 0600
    # Created /dev/mapper/temporary-cryptsetup-1671
    # temporary-cryptsetup-1671: Processing NODE_READ_AHEAD 256 (flags=1)
    # temporary-cryptsetup-1671 (254:0): read ahead is 256
    # temporary-cryptsetup-1671: retaining kernel read ahead of 256 (requested 256)
    # dm remove temporary-cryptsetup-1671  OFT    [16384] (*1)
    # temporary-cryptsetup-1671: Stacking NODE_DEL
    # temporary-cryptsetup-1671: Processing NODE_DEL
    # Removed /dev/mapper/temporary-cryptsetup-1671
    # Generating LUKS header version 1 using hash sha1, aes, xts-plain64, MK 32 bytes
    # KDF pbkdf2, hash sha1: 220289 iterations per second.
    # Data offset 4096, UUID c5f93c64-3c01-4aaa-92a9-c60d2530c5a1, digest iterations 26875
    # Updating LUKS header of size 1024 on device /dev/mmcblk0p3
    # Key length 32, device size 524288 sectors, header size 2050 sectors.
    # Reading LUKS header of size 1024 from device /dev/mmcblk0p3
    # Key length 32, device size 524288 sectors, header size 2050 sectors.
    # Adding new keyslot -1 using volume key.
    # Calculating data for key slot 0
    # KDF pbkdf2, hash sha1: 229950 iterations per second.
    # Key slot 0 use 112280 password iterations.
    # Using hash sha1 for AF in key slot 0, 4000 stripes
    # Updating key slot 0 [0x1000] area.
    # Userspace crypto wrapper cannot use aes-xts[ 1044.545582] [c5] bio: create slab <bio-1> a1
    -plain64 (-95).
    # Using dmcrypt to access keyslot area.
    # Calculated device size is 250 sectors (RW), offset 8.
    # DM-UUID is CRYPT-TEMP-temporary-cryptsetup-1671
    # dm create temporary-cryptsetup-1671 CRYPT-TEMP-temporary-cryptsetup-1671 OF   [16384] (*1)
    # dm reload temporary-cryptsetup-1671  OFW    [16384] (*1)
    # dm resume temporary-cryptsetup-1671  OFW    [16384] (*1)
    # temporary-cryptsetup-1671: Stacking NODE_ADD (254,0) 0:0 0600
    # temporary-cryptsetup-1671: Stacking NODE_READ_AHEAD 256 (flags=1)
    # temporary-cryptsetup-1671: Processing NODE_ADD (254,0) 0:0 0600
    # Created /dev/mapper/temporary-cryptsetup-1671
    # temporary-cryptsetup-1671: Processing NODE_READ_AHEAD 256 (flags=1)
    # temporary-cryptsetup-1671 (254:0): read ahead is 256
    # temporary-cryptsetup-1671: retaining kernel read ahead of 256 (requested 256)
    # dm remove temporary-cryptsetup-1671  OFT    [16384] (*1)
    # temporary-cryptsetup-1671: Stacking NODE_DEL
    # temporary-cryptsetup-1671: Processing NODE_DEL
    # Removed /dev/mapper/temporary-cryptsetup-1671
    # Key slot 0 was enabled in LUKS header.
    # Updating LUKS header of size 1024 on device /dev/mmcblk0p3
    # Key length 32, device size 524288 sectors, header size 2050 sectors.
    # Reading LUKS header of size 1024 from device /dev/mmcblk0p3
    # Key length 32, device size 524288 sectors, header size 2050 sectors.
    # Releasing crypt device /dev/mmcblk0p3 context.
    # Releasing device-mapper backend.
    # Unlocking memory.
    Command successful.

We need  to format the inside of the LUKS partiton to EXT4::
    
    # cryptsetup --debug open --type luks /dev/mmcblk0p3 usrfs1
    # cryptsetup 1.6.6 processing "cryptsetup --debug open --type luks /dev/mmcblk0p3 usrfs1"
    # Running command open.
    # Locking memory.
    # Installing SIGINT/SIGTERM handler.
    # Unblocking interruption on signal.
    # Allocating crypt device /dev/mmcblk0p3 context.
    # Trying to open and read device /dev/mmcblk0p3.
    # Initialising device-mapper backend library.
    # Trying to load LUKS1 crypt type from device /dev/mmcblk0p3.
    # Crypto backend (gcrypt 1.6.2) initialized.
    # Detected kernel Linux 3.10.63 armv7l.
    # Reading LUKS header of size 1024 from device /dev/mmcblk0p3
    # Key length 32, device size 524288 sectors, header size 2050 sectors.
    # Timeout set to 0 miliseconds.
    # Password retry count set to 3.
    # Password verification disabled.
    # Iteration time set to 1000 miliseconds.
    # Activating volume usrfs1 [keyslot -1] using [none] passphrase.
    # dm version   OF   [16384] (*1)
    # dm versions   OF   [16384] (*1)
    # Detected dm-crypt version 1.12.1, dm-ioctl version 4.24.0.
    # Device-mapper backend running with UDEV support disabled.
    # dm status usrfs1  OF   [16384] (*1)
    # Interactive passphrase entry requested.
    Enter passphrase for /dev/mmcblk0p3: 
    # Trying to open key slot 0 [ACTIVE_LAST].
    # Reading key slot 0 area.
    # Userspace crypto wrapper cannot use aes-xts[ 2252.981869] [c5] bio: create slab <bio-1> a1
    -plain64 (-95).
    # Using dmcrypt to access keyslot area.
    # Calculated device size is 250 sectors (RW), offset 8.
    # DM-UUID is CRYPT-TEMP-temporary-cryptsetup-1704
    # dm create temporary-cryptsetup-1704 CRYPT-TEMP-temporary-cryptsetup-1704 OF   [16384] (*1)
    # dm reload temporary-cryptsetup-1704  OFRW    [16384] (*1)
    # dm resume temporary-cryptsetup-1704  OFRW    [16384] (*1)
    # temporary-cryptsetup-1704: Stacking NODE_ADD (254,0) 0:0 0600
    # temporary-cryptsetup-1704: Stacking NODE_READ_AHEAD 256 (flags=1)
    # temporary-cryptsetup-1704: Processing NODE_ADD (254,0) 0:0 0600
    # Created /dev/mapper/temporary-cryptsetup-1704
    # temporary-cryptsetup-1704: Processing NODE_READ_AHEAD 256 (flags=1)
    # temporary-cryptsetup-1704 (254:0): read ahead is 256
    # temporary-cryptsetup-1704: retaining kernel read ahead of 256 (requested 256)
    # dm remove temporary-cryptsetup-1704  OFT    [16384] (*1)
    # temporary-cryptsetup-1704: Stacking NODE_DEL
    # temporary-cryptsetup-1704: Processing NODE_DEL
    # Removed /dev/mapper/temporary-cryptsetup-1704
    Key slot 0 unlocked.
    # Calculated device siz[ 2253.168551] [c5] bio: create slab <bio-1> at 1
    e is 520192 sectors (RW), offset 4096.
    # DM-UUID is CRYPT-LUKS1-c5f93c643c014aaa92a9c60d2530c5a1-usrfs1
    # dm create usrfs1 CRYPT-LUKS1-c5f93c643c014aaa92a9c60d2530c5a1-usrfs1 OF   [16384] (*1)
    # dm reload usrfs1  OFW    [16384] (*1)
    # dm resume usrfs1  OFW    [16384] (*1)
    # usrfs1: Stacking NODE_ADD (254,0) 0:0 0600
    # usrfs1: Stacking NODE_READ_AHEAD 256 (flags=1)
    # usrfs1: Processing NODE_ADD (254,0) 0:0 0600
    # Created /dev/mapper/usrfs1
    # usrfs1: Processing NODE_READ_AHEAD 256 (flags=1)
    # usrfs1 (254:0): read ahead is 256
    # usrfs1: retaining kernel read ahead of 256 (requested 256)
    # Releasing crypt device /dev/mmcblk0p3 context.
    # Releasing device-mapper backend.
    # Unlocking memory.
    Command successful.
    
    # ls /dev/mapper/
    control  usrfs1

    # mkfs.ext4 /dev/mapper/usrfs1 
    mke2fs 1.42.12 (29-Aug-2014)
    Creating filesystem with 260096 1k blocks and 65024 inodes
    Filesystem UUID: 225d47cd-8688-4552-bdb3-ed8f3bf430e8
    Superblock backups stored on blocks: 
            8193, 24577, 40961, 57345, 73729, 204801, 221185
    
    Allocating group tables: done                            
    Writing inode tables: done                            
    Creating journal (4096 blocks): done
    Writing superblocks and filesystem accounting information: done 



We can now mount it to add a file into it::

    # mount /dev/mapper/usrfs1 /mnt/usrfs/
    [ 2478.755842] [c7] EXT4-fs (dm-0): couldn't mount as ext3 due to feature incompatibilities
    [ 2478.763370] [c7] EXT4-fs (dm-0): couldn't mount as ext2 due to feature incompatibilities
    [ 2478.780388] [c7] EXT4-fs (dm-0): mounted filesystem with ordered data mode. Opts: (null)
    # mount
    rootfs on / type rootfs (rw)
    /dev/root on / type ext4 (rw,relatime,errors=remount-ro,data=ordered)
    devtmpfs on /dev type devtmpfs (rw,relatime,size=765136k,nr_inodes=120937,mode=755)
    proc on /proc type proc (rw,relatime)
    devpts on /dev/pts type devpts (rw,relatime,gid=5,mode=620)
    tmpfs on /dev/shm type tmpfs (rw,relatime,mode=777)
    tmpfs on /tmp type tmpfs (rw,relatime)
    sysfs on /sys type sysfs (rw,relatime)
    /dev/mapper/usrfs1 on /mnt/usrfs type ext4 (rw,relatime,data=ordered)
    
We can navigate to the partition and create some file::

    # cd /mnt/usrfs/
    # ls
    lost+found
    # touch some_empty_file
    # dd if=/dev/urandom of=some_ramdom_data_file count=4k
    4096+0 records in
    4096+0 records out
    # ls -lh
    total 2060
    drwx------    2 root     root       12.0K Jan  1 00:40 lost+found
    -rw-r--r--    1 root     root           0 Jan  1 00:42 some_empty_file
    -rw-r--r--    1 root     root        2.0M Jan  1 00:43 some_ramdom_data_file
    
We can add a key to the LUKS partition easly using the first generated key::

    # cryptsetup luksAddKey /dev/mmcblk0p3 
    Enter any existing passphrase: 
    Enter new passphrase for key slot: 
    Verify passphrase:
    
Then we can dump the LUKS header information and the crypted master key:::

    # cryptsetup luksDump /dev/mmcblk0p3
    LUKS header information for /dev/mmcblk0p3
    
    Version:        1
    Cipher name:    aes
    Cipher mode:    xts-plain64
    Hash spec:      sha1
    Payload offset: 4096
    MK bits:        256
    MK digest:      20 04 0d 26 a6 4e 31 16 b0 63 3e 04 8b e6 cd 00 c2 4b e2 d5 
    MK salt:        6f 6b f4 dd ac 12 27 2c 69 06 bc 67 53 86 38 38 
                    3d c9 f5 d0 03 c6 53 2c 1f e9 59 c3 89 06 45 b3 
    MK iterations:  26875
    UUID:           c5f93c64-3c01-4aaa-92a9-c60d2530c5a1
    
    Key Slot 0: ENABLED
            Iterations:             112280
            Salt:                   18 7b 76 b7 99 2c 1a e4 28 c4 29 66 9e 2f 98 0e 
                                    14 fd 1b 13 d6 1c f6 31 f5 2c 0b 83 01 15 9d de 
            Key material offset:    8
            AF stripes:             4000
    Key Slot 1: ENABLED
            Iterations:             110344
            Salt:                   ae c5 74 ee df 2c 63 1e a7 43 32 1e fb 98 4d 30 
                                    56 ac 40 a5 ef bd 92 12 db 83 fb ac 8b 0a 22 97 
            Key material offset:    264
            AF stripes:             4000
    Key Slot 2: DISABLED
    Key Slot 3: DISABLED
    Key Slot 4: DISABLED
    Key Slot 5: DISABLED
    Key Slot 6: DISABLED
    Key Slot 7: DISABLED

    # cryptsetup luksDump --dump-master-key /dev/mmcblk0p3
    
    WARNING!
    ========
    Header dump with volume key is sensitive information
    which allows access to encrypted partition without passphrase.
    This dump should be always stored encrypted on safe place.
    
    Are you sure? (Type uppercase yes): YES
    Enter passphrase: 
    LUKS header information for /dev/mmcblk0p3
    Cipher name:    aes
    Cipher mode:    xts-plain64
    Payload offset: 4096
    UUID:           c5f93c64-3c01-4aaa-92a9-c60d2530c5a1
    MK bits:        256
    MK dump:        83 8d 75 73 03 02 22 43 13 6c 87 fb 96 a7 a6 2e 
                    1d b4 dc 15 ee e7 d7 49 67 a4 3d 95 9f 0f 90 c8 


If we dump 1Mbytes of the partition::

    # dd if=/dev/mmcblk0p3 of=luks_dump bs=1024 count=1024
    1024+0 records in
    1024+0 records out
    # ls -lh luks_dump 
    -rw-r--r--    1 root     root        1.0M Jan  1 01:06 luks_dump
    
    
And open it with an Hexadecimal editor, we can find the LUKS header at offset 0x70 but the master key cannot be seen as it need to be decrypted with a key. The key hash are visible at offset 0xD8 and 0x106:


    .. image:: ../../lab6/hex_editor_LUKS.png


If we connect the SDCard to the host PC, the desktop environement of ubuntu request the password for the LUKS partition. If we provide it, the partition is mounted and is browsable:

    .. image:: ../../lab6/LUKS_inserted.png


Question 6.4: rootfs in a LUKS partition
----------------------------------------

We can first create a passfrase into a file using *dd*::
    
    antoine@antoine-vb-64:~/master/Ses/lab6$ dd if=/dev/urandom of=passphrase bs=1 count=64
    64+0 records in
    64+0 records out
    64 bytes (64 B) copied, 0.0012072 s, 53.0 kB/s
    
    
We can then use this file to create the LUKS partition:: 

    antoine@antoine-vb-64:~/master/Ses/lab6$ sudo cryptsetup luksFormat --key-size 512 --hash sha512 /dev/sdb3 passphrase
    
    WARNING!
    ========
    This will overwrite data on /dev/sdb3 irrevocably.
    
    Are you sure? (Type uppercase yes): YES
    antoine@antoine-vb-64:~/master/Ses/lab6$ cryptsetup open --type luks /dev/sdb3 usrfs1 --key-file passphrase --debug
    # cryptsetup 1.6.1 processing "cryptsetup open --type luks /dev/sdb3 usrfs1 --key-file passphrase --debug"
    # Running command open.
    # Locking memory.
    # Cannot lock memory with mlockall.
    # Installing SIGINT/SIGTERM handler.
    # Unblocking interruption on signal.
    # Allocating crypt device /dev/sdb3 context.
    # Trying to open and read device /dev/sdb3.
    Device /dev/sdb3 doesn't exist or access denied.
    Command failed with code 15: Device /dev/sdb3 doesn't exist or access denied.
    antoine@antoine-vb-64:~/master/Ses/lab6$ sudo cryptsetup open --type luks /dev/sdb3 usrfs1 --key-file passphrase --debug
    # cryptsetup 1.6.1 processing "cryptsetup open --type luks /dev/sdb3 usrfs1 --key-file passphrase --debug"
    # Running command open.
    # Locking memory.
    # Installing SIGINT/SIGTERM handler.
    # Unblocking interruption on signal.
    # Allocating crypt device /dev/sdb3 context.
    # Trying to open and read device /dev/sdb3.
    # Initialising device-mapper backend library.
    # Trying to load LUKS1 crypt type from device /dev/sdb3.
    # Crypto backend (gcrypt 1.5.3) initialized.
    # Reading LUKS header of size 1024 from device /dev/sdb3
    # Key length 64, device size 524288 sectors, header size 4036 sectors.
    # Timeout set to 0 miliseconds.
    # Password retry count set to 3.
    # Password verification disabled.
    # Iteration time set to 1000 miliseconds.
    # Password retry count set to 1.
    # Activating volume usrfs1 [keyslot -1] using keyfile passphrase.
    # dm version   OF   [16384] (*1)
    # dm versions   OF   [16384] (*1)
    # Detected dm-crypt version 1.13.0, dm-ioctl version 4.27.0.
    # Device-mapper backend running with UDEV support enabled.
    # dm status usrfs1  OF   [16384] (*1)
    # File descriptor passphrase entry requested.
    # Trying to open key slot 0 [ACTIVE_LAST].
    # Reading key slot 0 area.
    # Calculated device size is 500 sectors (RW), offset 8.
    # DM-UUID is CRYPT-TEMP-temporary-cryptsetup-4054
    # Udev cookie 0xd4d9d7e (semid 262144) created
    # Udev cookie 0xd4d9d7e (semid 262144) incremented to 1
    # Udev cookie 0xd4d9d7e (semid 262144) incremented to 2
    # Udev cookie 0xd4d9d7e (semid 262144) assigned to CREATE task(0) with flags DISABLE_SUBSYSTEM_RULES DISABLE_DISK_RULES DISABLE_OTHER_RULES (0xe)
    # dm create temporary-cryptsetup-4054 CRYPT-TEMP-temporary-cryptsetup-4054 OF   [16384] (*1)
    # dm reload temporary-cryptsetup-4054  OFRW    [16384] (*1)
    # dm resume temporary-cryptsetup-4054  OFRW    [16384] (*1)
    # temporary-cryptsetup-4054: Stacking NODE_ADD (252,0) 0:6 0660 [verify_udev]
    # temporary-cryptsetup-4054: Stacking NODE_READ_AHEAD 256 (flags=1)
    # Udev cookie 0xd4d9d7e (semid 262144) decremented to 1
    # Udev cookie 0xd4d9d7e (semid 262144) waiting for zero
    # Udev cookie 0xd4d9d7e (semid 262144) destroyed
    # temporary-cryptsetup-4054: Processing NODE_ADD (252,0) 0:6 0660 [verify_udev]
    # temporary-cryptsetup-4054: Processing NODE_READ_AHEAD 256 (flags=1)
    # temporary-cryptsetup-4054 (252:0): read ahead is 256
    # temporary-cryptsetup-4054 (252:0): Setting read ahead to 256
    # Udev cookie 0xd4d57fd (semid 294912) created
    # Udev cookie 0xd4d57fd (semid 294912) incremented to 1
    # Udev cookie 0xd4d57fd (semid 294912) incremented to 2
    # Udev cookie 0xd4d57fd (semid 294912) assigned to REMOVE task(2) with flags (0x0)
    # dm remove temporary-cryptsetup-4054  OFT    [16384] (*1)
    # temporary-cryptsetup-4054: Stacking NODE_DEL [verify_udev]
    # Udev cookie 0xd4d57fd (semid 294912) decremented to 1
    # Udev cookie 0xd4d57fd (semid 294912) waiting for zero
    # Udev cookie 0xd4d57fd (semid 294912) destroyed
    # temporary-cryptsetup-4054: Processing NODE_DEL [verify_udev]
    Key slot 0 unlocked.
    # Calculated device size is 520192 sectors (RW), offset 4096.
    # DM-UUID is CRYPT-LUKS1-5f55e67ab6ea4e68b8b1eda64d5c604d-usrfs1
    # Udev cookie 0xd4d8fd8 (semid 327680) created
    # Udev cookie 0xd4d8fd8 (semid 327680) incremented to 1
    # Udev cookie 0xd4d8fd8 (semid 327680) incremented to 2
    # Udev cookie 0xd4d8fd8 (semid 327680) assigned to CREATE task(0) with flags (0x0)
    # dm create usrfs1 CRYPT-LUKS1-5f55e67ab6ea4e68b8b1eda64d5c604d-usrfs1 OF   [16384] (*1)
    # dm reload usrfs1  OFW    [16384] (*1)
    # dm resume usrfs1  OFW    [16384] (*1)
    # usrfs1: Stacking NODE_ADD (252,0) 0:6 0660 [verify_udev]
    # usrfs1: Stacking NODE_READ_AHEAD 256 (flags=1)
    # Udev cookie 0xd4d8fd8 (semid 327680) decremented to 1
    # Udev cookie 0xd4d8fd8 (semid 327680) waiting for zero
    # Udev cookie 0xd4d8fd8 (semid 327680) destroyed
    # usrfs1: Processing NODE_ADD (252,0) 0:6 0660 [verify_udev]
    # usrfs1: Processing NODE_READ_AHEAD 256 (flags=1)
    # usrfs1 (252:0): read ahead is 256
    # usrfs1 (252:0): Setting read ahead to 256
    # Releasing crypt device /dev/sdb3 context.
    # Releasing device-mapper backend.
    # Unlocking memory.
    Command successful.

Now that the crypted patition is open (mapped), we can format the inside to EXT4 like on question 6.3::

    antoine@antoine-vb-64:~/master/Ses/lab6$ sudo mkfs.ext4 /dev/mapper/usrfs1 
    mke2fs 1.42.9 (4-Feb-2014)
    Filesystem label=
    OS type: Linux
    Block size=1024 (log=0)
    Fragment size=1024 (log=0)
    Stride=0 blocks, Stripe width=0 blocks
    65024 inodes, 260096 blocks
    13004 blocks (5.00%) reserved for the super user
    First data block=1
    Maximum filesystem blocks=67371008
    32 block groups
    8192 blocks per group, 8192 fragments per group
    2032 inodes per group
    Superblock backups stored on blocks: 
    	8193, 24577, 40961, 57345, 73729, 204801, 221185
    
    Allocating group tables: done                            
    Writing inode tables: done                            
    Creating journal (4096 blocks): done
    Writing superblocks and filesystem accounting information: done 
    
Finally, we can write the rootfs to the mapped partition and close it   ::


    antoine@antoine-vb-64:~/master/Ses/lab6$ sudo dd if=~/workspace/xu3/buildroot/output/images/rootfs.ext4 of=/dev/mapper/usrfs1 bs=4M
    12+1 records in
    12+1 records out
    53684224 bytes (54 MB) copied, 3.9151 s, 13.7 MB/s
    
    antoine@antoine-vb-64:~/master/Ses/lab6$ sync
    antoine@antoine-vb-64:~/master/Ses/lab6$ sudo cryptsetup close usrfs1
    antoine@antoine-vb-64:~/master/Ses/lab6$ ls /dev/mapper/
    control


We will need the passphrase to mount the LUKS partition from the Odroid. So we need to copy the file to the clear rootfs in the second partition::


    antoine@antoine-vb-64:~/master/Ses/lab6$ sudo cp passphrase /media/antoine/f322f0ad-3371-49fb-9d5e-36b5290d8a9f/root/
    [sudo] password for antoine: 
    


We can then boot the Odroid and try to mount the partition::

    # cryptsetup open --type luks /dev/mmcblk0p3 usrfs1 --key-file passphrase 
    [  261.883447] [c3] bio: create slab <bio-1> at 1
    [  262.186935] [c4] bio: create slab <bio-1> at 1
    # mkdir /mnt/luks
    # mount /dev/mapper/usrfs1 /mnt/luks
    [  300.796166] [c6] EXT4-fs (dm-0): couldn't mount as ext3 due to feature incompatibilities
    [  300.803820] [c6] EXT4-fs (dm-0): couldn't mount as ext2 due to feature incompatibilities
    [  301.002415] [c6] EXT4-fs (dm-0): mounted filesystem with ordered data mode. Opts: (null)
    # mount
    rootfs on / type rootfs (rw)
    /dev/root on / type ext4 (rw,relatime,errors=remount-ro,data=ordered)
    devtmpfs on /dev type devtmpfs (rw,relatime,size=765136k,nr_inodes=120937,mode=755)
    proc on /proc type proc (rw,relatime)
    devpts on /dev/pts type devpts (rw,relatime,gid=5,mode=620)
    tmpfs on /dev/shm type tmpfs (rw,relatime,mode=777)
    tmpfs on /tmp type tmpfs (rw,relatime)
    sysfs on /sys type sysfs (rw,relatime)
    /dev/mapper/usrfs1 on /mnt/luks type ext4 (rw,relatime,errors=remount-ro,data=ordered)
    # 



Question 7: initramfs
---------------------

Question 8: initramfs-LUKS partition
------------------------------------




