#!/bin/bash
##分区
read -p "do you want to adjust the partition ? (input y to use fdisk or enter to continue:  " TMP
if [ "$TMP" == y ]
then fdisk -l
read -p "which disk do you want to partition ? (/dev/sdX:  " DISK
fdisk $DISK
fi
fdisk -l
read -p "input the / mount point:  " ROOT
read -p "format it ? (y or enter  " TMP
if [ "$TMP" == y ]
then read -p "input y to use ext4 defalut to use btrfs  " TMP
if [ "$TMP" == y ]
then mkfs.ext4 $ROOT
else mkfs.btrfs $ROOT -f
fi
mount $ROOT /mnt
fi
read -p "do you have the /boot mount point? (y or enter  " BOOT
if [ "$BOOT" == y ]
then fdisk -l
read -p "input the /boot mount point:  " BOOT
read -p "format it ? (y or enter  " TMP
if [ "$TMP" == y ]
then mkfs.fat -F32 $ROOT
fi
mkdir /mnt/boot
mount $BOOT /mnt/boot
fi
read -p "do you have the swap partition ? (y or enter  " SWAP
if [ "$SWAP" == y ]
then fdisk -l
read -p "input the swap mount point:  " SWAP
read -P "format it ? (y or enter  " TMP
if [ "$TMP" == y ]
then mkswap $SWAP
fi
swapon $SWAP
fi
##更改软件源
echo "## China                                                                                               
#Server = http://mirrors.163.com/archlinux/\$repo/os/\$arch                                               
Server = http://mirrors.ustc.edu.cn/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist
read -p "edit the pacman.conf ? (y or enter  " TMP
if [ "$TMP" == y ]
then
nano /etc/pacman.conf
fi
##安装基本系统
TMP=n
while [ "$TMP" == n ]
do
pacstrap /mnt base base-devel --force
rm /mnt/etc/fstab
genfstab -U -p /mnt >> /mnt/etc/fstab
read -p "successfully installed ? (n or enter  " TMP
done
##进入已安装的系统
wget https://raw.githubusercontent.com/yangxins/Arch/master/config.sh
mv config.sh /mnt/root/config.sh
chmod +x /mnt/root/config.sh
arch-chroot /mnt /root/config.sh
