#!/bin/bash

set -e

color(){
    case $1 in
        red)
            echo -e "\033[31m$2\033[0m"
        ;;
        yellow)
            echo -e "\033[33m$2\033[0m"
        ;;
    esac
}

config_base(){
    color yellow "Input your hostname"
    read TMP
    echo $TMP > /etc/hostname
    color yellow "Change your root passwd"
    passwd
}

config_locale(){
    color yellow "Please choose your locale time"
    select TIME in `ls /usr/share/zoneinfo`;do
        if [ -d "/usr/share/zoneinfo/$TIME" ];then
            select time in `ls /usr/share/zoneinfo/$TIME`;do
                ln -sf /usr/share/zoneinfo/$TIME/$time /etc/localtime
                break
            done
        else
            ln -sf /usr/share/zoneinfo/$TIME /etc/localtime
            break
        fi
        break
    done
    hwclock --systohc --utc
    color yellow "Choose your language"
    select LNAG in "en_US.UTF-8" "zh_CN.UTF-8";do
        echo "$LNAG UTF-8" > /etc/locale.gen
        locale-gen
        echo LANG=$LANG > /etc/locale.conf
        break
    done
}

install_grub(){
    if (mount | grep efivarfs > /dev/null 2>&1);then
        pacman -S --noconfirm grub efibootmgr -y
        grub-install --target=`uname -m`-efi --efi-directory=/boot --bootloader-id=Arch
        grub-mkconfig -o /boot/grub/grub.cfg
    else
        pacman -S --noconfirm grub
        fdisk -l
        color yellow "Input the disk you want to install grub (/dev/sdX"
        read TMP
        grub-install --target=i386-pc $TMP
        grub-mkconfig -o /boot/grub/grub.cfg
    fi
}

install_bootctl(){
    if (mount | grep efivarfs > /dev/null 2>&1);then
        bootctl --path=esp install
        bootctl --path=esp update
    else
        color yellow "Looks like your PC doesn't suppot UEFI or not in UEFI mode ENTER to use grub. Input q to quit"
        read TMP
        if [ "$TMP" == "" ];then
            install_grub
        else
            exit
        fi
    fi
}

add_user(){
    color yellow "Input the user name you want to use (must be lower case)"
    read USER
    useradd -m -g wheel $USER
    usermod -aG root,bin,daemon,tty,disk,network,video,audio $USER
    color yellow "Set the passwd"
    passwd $USER
    pacman -S --noconfirm sudo
    sed -i 's/\# \%wheel ALL=(ALL) ALL/\%wheel ALL=(ALL) ALL/g' /etc/sudoers
    sed -i 's/\# \%wheel ALL=(ALL) NOPASSWD: ALL/\%wheel ALL=(ALL) NOPASSWD: ALL/g' /etc/sudoers
}

install_graphic(){
    color yellow "What is your video graphic card?"
    select GPU in "Intel" "Nvidia" "Intel and Nvidia" "AMD";do
        case $GPU in
            "Intel")
                pacman -S --noconfirm xf86-video-intel -y
                break
            ;;
            "Nvidia")
                color yellow "Version of nvidia-driver to install"
                select NVIDIA in "GeForce-8 and newer" "GeForce-6/7" "Older";do
                    case $NVIDIA in
                        "GeForce-8 and newer")
                            pacman -S --noconfirm nvidia -y
                            break
                        ;;
                        "GeForce-6/7")
                            pacman -S --noconfirm nvidia-304xx -y
                            break
                        ;;
                        "Older")
                            pacman -S --noconfirm nvidia-340xx -y
                            break
                        ;;
                        *)
                            color red "Error ! Please input the correct num"
                        ;;
                    esac
                done
                break
            ;;
            "Intel and Nvidia")
                pacman -S --noconfirm bumblebee -y
                systemctl enable bumblebeed
                color yellow "Version of nvidia-driver to install"
                select NVIDIA in "GeForce-8 and newer" "GeForce-6/7" "Older";do
                    case $NVIDIA in
                        "GeForce-8 and newer")
                            pacman -S --noconfirm nvidia -y
                            break
                        ;;
                        "GeForce-6/7")
                            pacman -S --noconfirm nvidia-304xx -y
                            break
                        ;;
                        "Older")
                            pacman -S --noconfirm nvidia-340xx -y
                            break
                        ;;
                        *)
                            color red "Error ! Please input the correct num"
                        ;;
                    esac
                done
                break
            ;;
            "AMD")
                pacman -S --noconfirm xf86-video-ati -y
                break
            ;;
            *)
                color red "Error ! Please input the correct num"
            ;;
        esac
    done
}

install_bluetooth(){
    pacman -S --noconfirm bluez
    systemctl enable bluetooth
    color yellow "Install blueman? y)YES ENTER)NO"
    read TMP
    if [ "$TMP" == "y" ];then
        pacman -S --noconfirm blueman
    fi
}

install_app(){
    color yellow "Install yaourt from archlinuxcn ? (just for China users) y)YES ENTER)NO"
    read TMP
    if [ "$TMP" == "y" ];then
        sed -i '/archlinuxcn/d' /etc/pacman.conf
        select MIRROR in "USTC" "TUNA" "163";do
            case $MIRROR in
                "USTC")
                    echo -e "[archlinuxcn]\nServer = https://mirrors.ustc.edu.cn/archlinuxcn/\$arch" >> /etc/pacman.conf
                    break
                ;;
                "TUNA")
                    echo -e "[archlinuxcn]\nServer = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/\$arch" >> /etc/pacman.conf
                    break
                ;;
                "163")
                    echo -e "[archlinuxcn]\nServer = http://mirrors.163.com/archlinux-cn/\$arch" >> /etc/pacman.conf
                    break
                ;;
                *)
                    color red "Error ! Please input the correct num"
                ;;
            esac
        done
        pacman -Sy
        pacman -S --noconfirm archlinuxcn-keyring
        pacman -S --noconfirm yaourt
    else
        pacman -S --noconfirm git
        su - $USER -c "cd ~
            git clone https://aur.archlinux.org/package-query.git
            cd package-query&&makepkg -si
            cd ..
            git clone https://aur.archlinux.org/yaourt.git
            cd yaourt&&makepkg -si
            cd ..
            rm -rf package-query yaourt"
        fi
    pacman -S --noconfirm networkmanager xorg-server firefox wqy-zenhei
    systemctl enable NetworkManager
    if [ "$GPU" == "Intel and Nvidia" ];then
        gpasswd -a $USER bumblebee
    fi
}

lightdm_config(){
    gpasswd -a $USER lightdm
    systemctl enable lightdm
}

install_desktop(){
    color yellow "Choose the desktop you want to use"
    select DESKTOP in "KDE" "Gnome" "Lxde" "Lxqt" "Mate" "Xfce" "Deepin" "Budgie" "Cinnamon";do
        case DESKTOP in
            "KDE")
                pacman -S --noconfirm plasma kdebase kdeutils kdegraphics kde-l10n-zh_cn sddm
                gpasswd -a $USER sddm
                systemctl enable sddm
                break
            ;;
            "Gnome")
                pacman -S --noconfirm gnome
                gpasswd -a $USER gdm
                systemctl enable gdm
                break
            ;;
            "Lxde")
                pacman -S --noconfirm lxde lightdm lightdm-gtk-greeter
                lightdm_config
                break
            ;;
            "Lxqt")
                pacman -S --noconfirm lxqt lightdm lightdm-gtk-greeter
                lightdm_config
                break
            ;;
            "Mate")
                pacman -S --noconfirm mate mate-extra lightdm lightdm-gtk-greeter
                lightdm_config
                break
            ;;
            "Xfce")
                pacman -S --noconfirm xfce4 xfce4-goodies lightdm lightdm-gtk-greeter
                lightdm_config
                break
            ;;
            "Deepin")
                pacman -S --noconfirm deepin deepin-extra lightdm lightdm-gtk-greeter
                lightdm_config
                sed -i '108s/#greeter-session=example-gtk-gnome/greeter-session=lightdm-deepin-greeter/' /etc/lightdm/lightdm.conf
                break
            ;;
            "Budgie")
                pacman -S--noconfirm budgie-desktop lightdm lightdm-gtk-greeter
                lightdm_config
                break
            ;;
            "Cinnamon")
                pacman -S --noconfirm cinnamon lightdm lightdm-gtk-greeter
                lightdm_config
                break
            ;;
            *)
                color red "Error ! Please input the correct num"
            ;;
        esac
    done
}

main(){
    config_base
    config_locale
    color yellow "Use GRUB or Bootctl ? y)Bootctl ENTER)GRUB"
    read TMP
    if [ "$TMP" == "y" ];then
        install_bootctl
    else
        install_grub
    fi
    add_user
    install_graphic
    color yellow "Do you have bluetooth ? y)YES ENTER)NO"
    read TMP
    if [ "$TMP" == "y" ];then
        install_bluetooth
    fi
    install_app
    install_desktop
}

main