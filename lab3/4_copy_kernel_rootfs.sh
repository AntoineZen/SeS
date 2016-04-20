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



#copy rootfs
echo "Copy rootfs"
sudo dd if=${IMAGEDIR}/rootfs.ext4 of=/dev/${TARGET_VOLUME} bs=512 seek=163840

#copy kernel & flattened device tree
sudo mount /dev/${TARGET_VOLUME}1 /mnt
echo "Copy kernel"
sudo cp ${IMAGEDIR}/uImage /mnt/


sudo umount /dev/${TARGET_VOLUME}1

# Show patition table
echo "Patition table is"
sudo fdisk -l /dev/${TARGET_VOLUME}

