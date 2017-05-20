#!/bin/bash
read -p "ENTER to continue "
##必要设置
ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime -f
hwclock --systohc --utc
echo zh_CN.UTF-8 UTF-8 > /etc/locale.gen
locale-gen
echo LANG=zh_CN.UTF-8 > /etc/locale.conf
read -p "Input your hostname:  " HOSTNAME
echo $HOSTNAME  > /etc/hostname
echo Change your root passwd
passwd
##安装引导
read -p "Are you efi ? (y or Enter  " TMP
if (("$TMP"=="y"))
then pacman -S grub efibootmgr -y&&grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Arch&&grub-mkconfig -o /boot/grub/grub.cfg
else pacman -S grub&&fdisk -l
read -p "Input the disk you want to install the grub  " GRUB
grub-install --target=i386-pc $GRUB
grub-mkconfig -o /boot/grub/grub.cfg
fi
##安装显卡驱动
VIDEO=5
while (($VIDEO!=1&&$VIDEO!=2&&VIDEO!=3&&VIDEO!=4));do
echo "What is your video card ?
[1]  intel
[2]  nvidia
[3]  intel/nvidia
[4]  ATI/AMD"
read VIDEO
if (($VIDEO==1))
then pacman -S xf86-video-intel -y
elif (($VIDEO==2))
then TMP=4
while (($TMP!=1&&$TMP!=2&&$TMP!=3));do
echo "Version of nvidia-driver to install:
[1]  GeForce-8 and newer
[2]  GeForce-6/7
[3]  Older  "
read TMP
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
echo "Version of nvidia-driver to install:
[1]  GeForce-8 and newer
[2]  GeForce-6/7
[3]  Older   " 
read TMP
if (($TMP==1))
then pacman -S nvidia -y
elif (($TMP==2))
then pacman -S nvidia-304xx -y
elif (($TMP==3))
then pacman -S nvidia-340xx -y
else echo Error ! Input the currect number
fi
done
elif (($VIDEO==4))
then pacman -S xf86-video-ati -y
else
echo Error ! Input the number again
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
read -p "Do you have bluetooth ? (y or Enter  " TMP
if [ "$TMP" == y ]
then pacman -S bluez blueman&&systemctl enable bluetooth
fi
read -p "Successfully installed ? (n or Enter  " TMP
done
##安装桌面环境
echo -e "\033[31m Which desktop you want to install :  \033[0m"
DESKTOP=0
while (($DESKTOP!=1&&$DESKTOP!=2&&$DESKTOP!=3&&$DESKTOP!=4&&$DESKTOP!=5&&$DESKTOP!=6&&$DESKTOP!=7&&$DESKTOP!=8&&$DESKTOP!=9));do
echo "[1]  Gnome
[2]  Kde
[3]  Lxde
[4]  Lxqt
[5]  Mate
[6]  Xfce
[7]  Deepin
[8]  Budgie 
[9]  Cinnamon"
read DESKTOP
case $DESKTOP in
    1) pacman -S gnome
    ;;
    2) pacman -S plasma kde-applications kde-l10n-zh_cn sddm
    ;;
    3) pacman -S lxde lightdm lightdm-gtk-greeter 
    ;;
    4) pacman -S lxqt lightdm lightdm-gtk-greeter
    ;;
    5) pacman -S mate mate-extra lightdm lightdm-gtk-greeter
    ;;
    6) pacman -S xfce4 xfce4-goodies lightdm lightdm-gtk-greeter
    ;;
    7) pacman -S deepin deepin-extra lightdm lightdm-gtk-greeter
    ;;
    8) pacman -S budgie-desktop lightdm lightdm-gtk-greeter
    ;;
    9) pacman -S cinnamon ligthdm lightdm-gtk-greeter
    ;;
    *) echo Error ! Input the number again
    ;;
esac
done
##建立用户
read -p "Input the user name you want to use :  " USER
useradd -m -g wheel $USER
passwd $USER
usermod -aG root,bin,daemon,tty,disk,games,network,video,audio $USER
if (($VIDEO==4))
then  gpasswd -a $USER bumblebee
fi
if (($DESKTOP==1))
then gpasswd -a $USER gdm
systemctl enable gdm
elif (($DESKTOP==2))
then gpasswd -a $USER sddm
systemctl enable sddm
else gpasswd -a $USER lightdm
systemctl enable lightdm
fi
