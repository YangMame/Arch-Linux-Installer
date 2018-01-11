#!/bin/bash

# 该死的颜色
color(){
    case $1 in
        red)
            echo -e "\033[31m$2\033[0m"
        ;;
        green)
            echo -e "\033[32m$2\033[0m"
        ;;
        yellow)
            echo -e "\033[33m$2\033[0m"
        ;;
        blue)
            echo -e "\033[34m$2\033[0m"
        ;;
    esac
}

partition(){
    if (echo $1 | grep '/' > /dev/null);then
        :
    else
        other=/$1
    fi

    fdisk -l
    color green "Input the partition (/dev/sdaX"
    read OTHER
    color green "Format it ? y)yes ENTER)no"
    read tmp

    if [ "$tmp" == y ];then
        umount $OTHER > /dev/null 2>&1
        color green "Input the filesystem's num to format it"
        select type in 'ext2' "ext3" "ext4" "btrfs" "xfs" "jfs" "fat" "swap";do
            case $type in
                "ext2")
                    mkfs.ext2 $OTHER
                    break
                ;;
                "ext3")
                    mkfs.ext3 $OTHER
                    break
                ;;
                "ext4")
                    mkfs.ext4 $OTHER
                    break
                ;;
                "btrfs")
                    mkfs.btrfs $OTHER -f
                    break
                ;;
                "xfs")
                    mkfs.xfs $OTHER -f
                    break
                ;;
                "jfs")
                    mkfs.jfs $OTHER
                    break
                ;;
                "fat")
                    mkfs.fat -F32 $OTHER
                    break
                ;;
                "swap")
                    swapoff $OTHER > /dev/null 2>&1
                    mkswap $OTHER -f
                    break
                ;;
                *)
                    color red "Error ! Please input the num again"
                ;;
            esac
        done
    fi

    if [ "$other" == "/swap" ];then
        swapon $OTHER
    else
        umount $OTHER > /dev/null 2>&1
        mkdir /mnt$other
        mount $OTHER /mnt$other
    fi
}

prepare(){
    fdisk -l
    color green "Do you want to adjust the partition ? y)yes ENTER)no"
    read tmp
    if [ "$tmp" == y ];then
        color green "Input the disk (/dev/sdX"
        read TMP
        cfdisk $TMP
    fi
    color green "Input the ROOT(/) mount point:"
    read ROOT
    color green "Format it ? y)yes ENTER)no"
    read tmp
    if [ "$tmp" == y ];then
        umount $ROOT > /dev/null 2>&1
        color green "Input the filesystem's num to format it"
        select type in "ext4" "btrfs" "xfs" "jfs";do
            umount $ROOT > /dev/null 2>&1
            mkfs.$type $ROOT
            break
        done
    fi
    mount $ROOT /mnt
    color green "Do you have another mount point ? if so please input it, such as : /boot /home and swap or just ENTER to skip"
    read other
    while [ "$other" != '' ];do
        partition $other
        color green "Still have another mount point ? input it or just ENTER"
        read other
    done
}

install(){
    color green 'Choose the mirror you want to use (input the num'
    select mirror in "USTC" "TUNA" "163" "LeaseWeb";do
        case $mirror in
            "USTC")
                echo "Server = http://mirrors.ustc.edu.cn/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist
                break
            ;;
            "TUNA")
                echo "Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist
                break
            ;;
            "163")
                echo "Server = http://mirrors.163.com/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist
                break
            ;;
            "LeaseWeb")
                echo "Server = http://mirror.wdc1.us.leaseweb.net/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist
                break
            ;;
            *)
                color red "Please input the correct num"
            ;;
        esac
    done
    pacstrap /mnt base base-devel --force
    genfstab -U -p /mnt > /mnt/etc/fstab
}

config(){
    wget https://raw.githubusercontent.com/YangMame/Arch-Installer/master/config.sh -O /mnt/root/config.sh
    chmod +x /mnt/root/config.sh
    arch-chroot /mnt /root/config.sh
}

if [ "$1" != '' ];then
    case $1 in
        "--prepare")
            prepare
        ;;
        "--install")
            install
        ;;
        "--chroot")
            config
        ;;
        "--help")
            color red "--prepare :  prepare disk and partition\n--install :  install the base system\n--chroot :  chroot into the system to install other software"
        ;;
        *)
            color red "--prepare :  prepare disk and partition\n--install :  install the base system\n--chroot :  chroot into the system to install other software"
        ;;
    esac
else
    prepare
    install
    config
fi