#!/bin/bash
##分区
read -p "do you want to adjust the partition ? (input y to use fdisk or enter to continue: " TMP
if (("$TMP" == "y"))
then fdisk -l
read -p "which disk do you want to partition ? (/dev/sdX: " DISK
fdisk $DISK
fi
fdisk -l
read -p "input the / mount point: " ROOT
mount $ROOT /mnt
read -p "do you have the /boot mount point? (y or enter " BOOT
if (("$BOOT" == "y"))
then read -p "input the /boot mount point: " BOOT
mkdir /mnt/boot
mount $BOOT /mnt/boot
fi
echo "do you have the swap partition ? (y or enter " SWAP
if (("$SWAP" == "y"))
then read -p "input the swap mount point: " SWAP
swapon $SWAP
fi
##更改软件源
echo "## China                                                                                               
Server = http://mirrors.163.com/archlinux/\$repo/os/\$arch                                               
Server = http://mirrors.ustc.edu.cn/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist
nano /etc/pacman.conf
##安装基本系统
pacstrap /mnt base base-devel
genfstab -U /mnt >> /mnt/etc/fstab
##进入已安装的系统
mv config.sh /mnt/root/install.sh
chmod 777 /mnt/root/install.sh
arch-chroot /mnt /bin/bash