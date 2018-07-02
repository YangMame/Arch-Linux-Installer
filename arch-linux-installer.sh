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
    esac
}

partition(){
    if (echo $1 | grep '/' > /dev/null 2>&1);then
        other=$1
    else
        other=/$1
    fi

    fdisk -l
    color green "Input the partition (/dev/sdaX"
    read OTHER
    color green "Format it ? y)yes ENTER)no"
    read tmp

    if [ "$other" == "/boot" ];then
        boot=$OTHER
    fi

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
            if [ "$type" == "btrfs" ];then
                mkfs.$type $ROOT -f
            elif [ "$type" == "xfs" ];then
                mkfs.$type $ROOT -f
            else
                mkfs.$type $ROOT
            fi
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

    color green "Please choose your country (for Generate the pacman mirror list"
    select COUNTRY in "AU" "AT" "BD" "BY" "BE" "BA" "BR" "BG" "CA" "CL" "CN" "CO" "HR" "CZ" "DK" "EC" "FI" "FR" "DE" "GR" "HK" "HU" "IS" "IN" "ID" "IR" "IE" "IL" "IT" "JP" "KZ" "LV" "LT" "LU" "MK" "MX" "AN" "NC" "NZ" "NO" "PH" "PL" "PT" "QA" "RO" "RU" "RS" "SG" "SK" "SI" "ZA" "KR" "ES" "SE" "CH" "TW" "TH" "TR" "UA" "GB" "US" "VN";do
        mv /etc/pacman.d/mirrorlist /etc/mirrorlist.bak
        color green "Generating mirror list , Please wait"
        wget https://www.archlinux.org/mirrorlist/\?country=$COUNTRY\&protocol=https -O /etc/pacman.d/mirrorlist.new
        if (! grep -q https /etc/pacman.d/mirrorlist.new);then
            wget https://www.archlinux.org/mirrorlist/\?country=$COUNTRY\&protocol=http -O /etc/pacman.d/mirrorlist.new
        fi
        sed -i 's/#Server/Server/g' /etc/pacman.d/mirrorlist.new
        rm -f rankmirrors.sh
        wget https://raw.githubusercontent.com/YangMame/Arch-Linux-Installer/master/rankmirrors.sh
        bash rankmirrors.sh -n 3 /etc/pacman.d/mirrorlist.new > /etc/pacman.d/mirrorlist
        chmod +r /etc/pacman.d/mirrorlist
	break
done

    color red "Please choose the mirror you want to use by input the num"
    select mirror in "`tail -n 1 /etc/pacman.d/mirrorlist`" "`tail -n 2 /etc/pacman.d/mirrorlist | head -n 1`" "`tail -n 3 /etc/pacman.d/mirrorlist | head -n 1`";do
        echo $mirror > /etc/pacman.d/mirrorlist
    break
    done

    pacstrap /mnt base base-devel --force
    genfstab -U -p /mnt > /mnt/etc/fstab
}

config(){
    rm -rf /mnt/root/config.sh
    wget https://raw.githubusercontent.com/YangMame/Arch-Linux-Installer/master/config.sh -O /mnt/root/config.sh
    chmod +x /mnt/root/config.sh
    arch-chroot /mnt /root/config.sh $ROOT $boot
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
            color red "Error !\n--prepare :  prepare disk and partition\n--install :  install the base system\n--chroot :  chroot into the system to install other software"
        ;;
    esac
else
    prepare
    install
    config
fi
