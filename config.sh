#!/bin/bash
##必要设置
ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime -f
hwclock --systohc --utc
echo zh_CN.UTF-8 UTF-8 > /etc/locale.gen
locale-gen
echo LANG=zh_CN.UTF-8 > /etc/locale.conf
read -p "input your hostname:  " HOSTNAME
echo $HOSTNAME  > /etc/hostname
echo change your root passwd
passwd
##安装引导
read -p "are you efi ? (y or enter  " TMP
if [ "$TMP"== y ]
then pacman -S grub efibootmger -y&&grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Arch&&grub-mkconfig -o /boot/grub/grub.cfg
else pacman -S grub&&fdisk -l
read -p "input the disk you want to install the grub  " GRUB
grub-install --target=i386-pc $GRUB
grub-mkconfig -o /boot/grub/grub.cfg
fi
##安装显卡驱动
VIDEO=5
while (($VIDEO!=1&&$VIDEO!=2&&VIDEO!=3&&VIDEO!=4));do
read -p "what is your video card ? (input the number: intel-1 nvidia-2 intel/nvidia-3 ATI/AMD-4 " VIDEO
if (($VIDEO==1))
then pacman -S xf86-video-intel -y
elif (($VIDEO==2))
then TMP=4
while (($TMP!=1&&$TMP!=2&&$TMP!=3));do
read -p "version of nvidia-driver to install (input the number, 1--GeForce-8 and newer 2--GeForce-6/7 3--older  " TMP
if (($TMP==1))
then pacman -S nvidia -y
elif (($TMP==2))
then pacman -S nvidia-304xx -y
elif (($TMP==3))
then pacman -S nvidia-340xx -y
else echo error ! input the number again
fi
done
elif (($VIDEO == 3))
then pacman -S bumblebee -y
systemctl enable bumblebeed
TMP=4
while (($TMP!=1&&$TMP!=2&&$TMP!=3));do
read -p "version of nvidia-driver to install (input the number, 1--GeForce-8 and newer 2--GeForce-6/7 3--older   " TMP
if (($TMP==1))
then pacman -S nvidia -y
elif (($TMP==2))
then pacman -S nvidia-304xx -y
elif (($TMP==3))
then pacman -S nvidia-340xx -y
else echo error ! input the number again
fi
done
elif (($VIDEO==4))
then pacman -S xf86-video-ati -y
else
echo error ! input the number again
fi
done
##安装必要软件/简单配置
echo "[archlinuxcn]
Server = https://mirrors.ustc.edu.cn/archlinuxcn/\$arch" >> /etc/pacman.conf
TMP=n
while [ "$TMP" == n ]
do
pacman -Syu&&pacman -S archlinuxcn-keyring&&pacman -S iw wpa_supplicant dialog networkmanager xorg-server xterm firefox yaourt wqy-zenhei wqy-microhei gnome-keyring
systemctl enable NetworkManager
then read -p "do you have bluetooth ? (y or enter  " TMP
if [ "$TMP" == y ]
then pacman -S bluez blueman&&systemctl enable bluetooth
fi
read -p "successfully installed ? (n or enter  " TMP
done
##安装桌面环境
echo -e "\033[31m which desktop you want to install \033[0m"
DESKTOP=9
while (($DESKTOP!=1&&$DESKTOP!=2&&$DESKTOP!=3&&$DESKTOP!=4&&$DESKTOP!=5&&$DESKTOP!=6&&$DESKTOP!=7&&$DESKTOP!=8));do
read -p "gnome-1 kde-2 lxde-3 lxqt-4 mate-5 xfce-6 deepin-7 budgie-8   " DESKTOP
case $DESKTOP in
    1) pacman -S gnome --force&&systemctl enable gdm
    ;;
    2) pacman -S plasma kde-applications kde-l10n-zh_cn sddm --force&&systemctl enable sddm
    ;;
    3) pacman -S lxde lightdm lightdm-gtk-greeter --force&&systemctl enable lightdm
    ;;
    4) pacman -S lxqt lightdm lightdm-gtk-greeter --force&&systemctl enable lightdm
    ;;
    5) pacman -S mate mate-extra lightdm lightdm-gtk-greeter --force&&systemctl enable lightdm
    ;;
    6) pacman -S xfce4 xfce4-goodies lightdm lightdm-gtk-greeter --force&&systemctl enable lightdm
    ;;
    7) pacman -S deepin deepin-extra lightdm lightdm-gtk-greeter --force&&systemctl enable lightdm&&echo greeter-session=lightdm-deepin-greeter >>/etc/lightdm/lightdm.conf
    ;;
    8) pacman -S budgie-desktop lightdm lightdm-gtk-greeter --force&&systemctl enable lightdm
    ;;
    *) echo error ! input the number again
    ;;
esac
done
##建立用户
read -p "input the user name you want to use :  " USER
useradd -m -g wheel $USER
passwd $USER
usermod -aG root bin daemon tty disk games network video audio avahi $USER
if (($VIDEO==4))
then  gpasswd --add $USER bumblebee
fi
if (($DESKTOP==1))
then gpasswd --add $USER gdm
elif (($DESKTOP==2))
then gpasswd --add $USER sddm
else gpasswd --add lightdm
fi