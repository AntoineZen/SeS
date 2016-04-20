#!/bin/bash

TARGET_VOLUME=sdb
IMAGEDIR="/home/antoine/workspace/xu3/buildroot/output/images"

echo "Target volume is ${TARGET_VOLUME}"
echo "Image dir is ${IMAGEDIR}"

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

#initialize the fist sector to zero, to erase the patition table
sudo dd if=/dev/zero of=/dev/${TARGET_VOLUME} bs=512 count=1
sync

echo "First sector: msdos"
sudo parted /dev/${TARGET_VOLUME} mklabel msdos

# Create the 1st partition (bootfs), start 16MB, length 64MB
sudo parted /dev/${TARGET_VOLUME} mkpart primary ext4 32768s 163839s
# Create the 2nt partition (rootfs), start 80MB, length 256MB
sudo parted /dev/${TARGET_VOLUME} mkpart primary ext4 163840s 688127s
# Create the 3rd partition (usrfs), start 336MB, length 256MB
sudo parted /dev/${TARGET_VOLUME} mkpart primary ext4 688128s 1212415s

#Format ext4 1st, 2nd and 3rd partition
sudo mkfs.ext4 /dev/${TARGET_VOLUME}1 -L bootfs
sudo mkfs.ext4 /dev/${TARGET_VOLUME}2 -L rootfs
sudo mkfs.ext4 /dev/${TARGET_VOLUME}3 -L usrfs
sync

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


#copy firmware & bl1.bin, bl2.bin, tzsw.bin
echo "Copy bl1"
sudo dd if=${IMAGEDIR}/xu3-bl1.bin of=/dev/${TARGET_VOLUME} bs=512 seek=1

echo "Copy  bl2"
sudo dd if=${IMAGEDIR}/xu3-bl2.bin of=/dev/${TARGET_VOLUME} bs=512 seek=31

#copy u-boot
echo "Copy U-Boot"
sudo dd if=${IMAGEDIR}/u-boot.bin of=/dev/${TARGET_VOLUME} bs=512 seek=63

echo "Copy trustZone"
sudo dd if=${IMAGEDIR}/xu3-tzsw.bin of=/dev/${TARGET_VOLUME} bs=512 seek=719

#copy rootfs
echo "Copy rootfs"
sudo dd if=${IMAGEDIR}/rootfs.ext4 of=/dev/${TARGET_VOLUME} bs=512 seek=163840

#copy kernel & flattened device tree
sudo mount /dev/${TARGET_VOLUME}1 /mnt
echo "Copy kernel"
sudo cp ${IMAGEDIR}/uImage /mnt/

echo "copy device tree"
sudo cp ${IMAGEDIR}/exynos5422-odroidxu3.dtb /mnt/

sudo umount /dev/${TARGET_VOLUME}1

# Show patition table
echo "Patition table is"
sudo fdisk -l /dev/${TARGET_VOLUME}

