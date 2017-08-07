#!/bin/bash
##分区
read -p "Do you want to adjust the partition ? (Input y to use fdisk or Enter to continue:  " TMP
if [ "$TMP" == y ]
then fdisk -l
    read -p "Which disk do you want to partition ? (/dev/sdX:  " DISK
    fdisk $DISK
fi
fdisk -l
read -p "Input the / mount point:  " ROOT
read -p "Format it ? (y or Enter  " TMP
if [ "$TMP" == y ]
then read -p "Input y to use ext4 defalut to use btrfs  " TMP
    if [ "$TMP" == y ]
    then mkfs.ext4 $ROOT
    else mkfs.btrfs $ROOT -f
    fi
fi
mount $ROOT /mnt
read -p "Do you have the /boot mount point? (y or Enter  " BOOT
if [ "$BOOT" == y ]
then fdisk -l
    read -p "Input the /boot mount point:  " BOOT
    read -p "Format it ? (y or Enter  " TMP
    if [ "$TMP" == y ]
    then mkfs.fat -F32 $BOOT
    fi
    mkdir /mnt/boot
    mount $BOOT /mnt/boot
fi
read -p "Do you have the swap partition ? (y or Enter  " SWAP
if [ "$SWAP" == y ]
then fdisk -l
    read -p "Input the swap mount point:  " SWAP
    read -P "Format it ? (y or Enter  " TMP
    if [ "$TMP" == y ]
    then mkswap $SWAP
    fi
    swapon $SWAP
fi
##更改软件源
echo "## China
#Server = http://mirrors.163.com/archlinux/\$repo/os/\$arch
Server = http://mirrors.ustc.edu.cn/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist
read -p "Edit the pacman.conf ? (y or Enter  " TMP
if [ "$TMP" == y ]
then
    nano /etc/pacman.conf
fi
##安装基本系统
TMP=n
while [ "$TMP" == n ]
do
    pacstrap /mnt base base-devel --force
    genfstab -U -p /mnt > /mnt/etc/fstab
    read -p "Successfully installed ? (n or Enter  " TMP
done
##进入已安装的系统
wget https://raw.githubusercontent.com/yangxins/Arch-Installer/master/config.sh
mv config.sh /mnt/root/config.sh
chmod +x /mnt/root/config.sh
arch-chroot /mnt /root/config.sh
