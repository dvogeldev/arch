#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

function check_if_suceeded {
        sleep 7
        if [[ $result -gt 0 ]]
        then
                printf "${RED}ERROR, exiting now${NC}\n";
                exit;
        fi
}

#time
ln -sf /usr/share/zoneinfo/America/Detroit /etc/localtime
result=$? && check_if_suceeded

hwclock --systohc
result=$? && check_if_suceeded

#the following can be used after chroot as a sigle script
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
result=$? && check_if_suceeded

echo "LANG=en_US.UTF-8" > /etc/locale.conf

# set hostname
echo "dv-pc" > /etc/hostname
echo "127.0.0.1 localhost" > /etc/hosts
echo "::1 localhost" >> /etc/hosts
echo "192.168.0.210 dv-pc.localdomain dv-pc" >> /etc/hosts


#selecting fastest mirror
pacman -Syu --noconfirm reflector
result=$? && check_if_suceeded
printf "${GREEN}Fastest mirrors selected${NC}\n";

reflector -c "United States" -a 6 -l 30 -p https --sort rate --save /etc/pacman.d/mirrorlist
result=$? && check_if_suceeded

pacman -Syu --noconfirm \
         base-devel \
         btrfs-progs \
	 chezmoi \
	 emacs \
	 fd fzf bat exa nnn \
         git \
	 keybase kbfs \
         linux linux-firmware linux-headers amd-ucode \
         neovim \
         networkmanager \
	 numlockx \
         openssh \
	 ttf-roboto \


result=$? && check_if_suceeded
printf "${GREEN}Success all packages installed ${NC}\n";

#tell systemd to start network manager at boot, this enables Ethernet at boot.
systemctl enable NetworkManager
result=$? && check_if_suceeded
printf "${GREEN}Network Manager enabled ${NC}\n";

#enable sshd
systemctl enable sshd
result=$? && check_if_suceeded
printf "${GREEN}sshd daemon enabled ${NC}\n";

#initramfs
mv /etc/mkinitcpio.conf /etc/mkinitcpio.conf.orig

echo 'MODULES=""'  > /etc/mkinitcpio.conf
echo 'BINARIES=""'  >> /etc/mkinitcpio.conf
echo 'FILES=""'  >> /etc/mkinitcpio.conf
echo 'HOOKS="base udev autodetect modconf block keyboard encrypt btrfs filesystems fsck"' >> /etc/mkinitcpio.conf
result=$? && check_if_suceeded
printf "${GREEN}Hooks made ${NC}\n";

#mkinit fails without this file for soem reason
touch /etc/vconsole.conf
#Finally, recreate the initramfs image:
mkinitcpio -p linux
result=$? && check_if_suceeded
printf "${GREEN}Success MKINICPIO ${NC}\n";

#bootloader ssytemd-boot
bootctl --path=/boot install
result=$? && check_if_suceeded
printf "${GREEN} systemd boot installed ${NC}\n";

UUID=$(blkid | sed -n '/sda3/s/.UUID=\"\([^\"]*\)\".*/\1/p')
UUID=$(echo $UUID | cut -f2 -d":")
echo $UUID
echo "title Arch Linux" > /boot/loader/entries/arch.conf
echo "linux /vmlinuz-linux" >> /boot/loader/entries/arch.conf
#echo "initrd /intel-ucode.img" >> /boot/loader/entries/arch.conf
echo "initrd /initramfs-linux.img" >> /boot/loader/entries/arch.conf
echo "options cryptdevice=UUID=$UUID:luks:allow-discards root=/dev/mapper/luks rootflags=subvol=@ rd.luks.options=discard rw quiet mem_sleep_default=deep" >> /boot/loader/entries/arch.conf

echo > "default arch" > /boot/loader/loader.conf

echo "enter a new password for root:"
passwd
echo "done"

exit
