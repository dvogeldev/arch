
# Despite the popular opinion, I am facinated by the btrfs filesystem.
# atomic snapshots at almsot zero extra space is remarkable
# I am also a huge fan of encrytion
# This script can be curled and executed at a single go.
# prompts are minimised but some are unavoidable.
# this installation is made minimalistic so a new user could understand better.
#       todo: merge the segregated sub volumes and other recomendations proposed in https://www.youtube.com/watch?v=7ituCCKXmMM

#!/bin/bash

#check command success
#   a delay is by experience found to be mandatory to allow IO delays
#   rant: Why cant system calls for disk I/O not return otherwise not completed?
function check_if_suceeded {
        sleep 7;#mandatory i/o sync delay, ping me for alternate method.
        if [[ $result -gt 0 ]]
        then
		echo "ERROR";
                exit;
	fi
}

#define where system, swap and bootloader should be.
# /boot directory and swap partition are not encrypted.

## Desktop (dv-pc)
# DRIVE=/dev/nvme0n1
# BOOT_drv=/dev/nvme0n1p1
# SWAP_drv=/dev/nvme0n1p2
# SYSTEM_drv=/dev/nvme0n1p3

## Laptop (dv-tp)
# DRIVE=/dev/sda
# BOOT_drv=/dev/sda1
# SWAP_drv=/dev/sda2
# SYSTEM_drv=/dev/sda3

#remove possibly lingering legacy partition information
sgdisk --zap-all $DRIVE
result=$? && check_if_suceeded
echo "drive $DRIVE cleaned of tables"

sgdisk --clear \
         --new=1:0:+512MiB --typecode=1:ef00 \
         --new=2:0:+8GiB   --typecode=2:8200 \
         --new=3:0:0       --typecode=3:8300 \
           $DRIVE
result=$? && check_if_suceeded
echo "sgdisk completed"

#format sysetm partition as LUKS encrypted
# cryptsetup -v --key-size 512 --hash sha512 --iter-time 5000 luksFormat $SYSTEM_drv
cryptsetup -v -d 512 -h sha512 -i 5000 luksFormat $SYSTEM_drv
result=$? && check_if_suceeded
echo "system partition luks formated."

#open it
cryptsetup luksOpen $SYSTEM_drv luks
result=$? && check_if_suceeded
echo "system partition opened"

#format boot partition as FAT32.
mkfs.fat -F32 $BOOT_drv
result=$? && check_if_suceeded
echo "bootloader partition formatted as F32"

#a crypt partition upon decryption opens under /dev/mapper
#it can now be trated as any other partition
mkfs.btrfs /dev/mapper/luks
result=$? && check_if_suceeded
echo "encrypted LUKS sys partition formatted as btrfs"

#SWAP
# systemd swap could be a better idea but not recomended for btrfs.
mkswap $SWAP_drv
result=$? && check_if_suceeded
swapon $SWAP_drv
result=$? && check_if_suceeded
echo "swap configured"

#mount the encrypted LUKS partition to /mnt to enable btrfs.
mount /dev/mapper/luks /mnt
result=$? && check_if_suceeded
echo "decypted luks volume mounted, going to create sub volumes now"

#create btrfs subvolumes
#ROOT
btrfs subvolume create /mnt/@
result=$? && check_if_suceeded

#HOME
btrfs subvolume create /mnt/@home
result=$? && check_if_suceeded

#VAR
#/var is a noicy place. Best avoided in snapshots.
btrfs subvolume create /mnt/@var
result=$? && check_if_suceeded

#.snapshots
btrfs subvolume create /mnt/@snapshots
result=$? && check_if_suceeded

echo "subvols created"


#We have created the sub volumes. Let's now mount them instead.
# -R not mandatory but it will recursively un mount anything else mounted.
umount -R /mnt
result=$? && check_if_suceeded

mount -o subvol=@,ssd,compress=lzo,noatime,nodiratime /dev/mapper/luks /mnt
result=$? && check_if_suceeded

mkdir /mnt/{boot,home,var,.snapshots}
result=$? && check_if_suceeded

mount -o subvol=@home,ssd,compress=lzo,noatime,nodiratime /dev/mapper/luks /mnt/home
result=$? && check_if_suceeded

mount -o subvol=@var,ssd,compress=lzo,noatime,nodiratime /dev/mapper/luks /mnt/var
result=$? && check_if_suceeded

mount -o subvol=@snapshots,ssd,compress=lzo,noatime,nodiratime /dev/mapper/luks /mnt/.snapshots
result=$? && check_if_suceeded

#mount the EFI boot partition
mount $BOOT_drv /mnt/boot
result=$? && check_if_suceeded

mkdir -p /mnt/testdir
result=$? && check_if_suceeded
echo "testing for proper mounting" > /mnt/testdir/teststring
result=$? && check_if_suceeded

echo "all parts unmounted. All sub vols mounted instead, tested."

#commented as installing reflector while on USB boot causes space issues.
#USB disk may be has limited space.
        #select the best mirror
        #pacman -Syu --noconfirm --needed --noprogressbar --quiet reflector
        #result=$? && check_if_suceeded
        #reflector -c singapore -a 6 --sort rate --save /etc/pacman.d/mirrorlist
        #result=$? && check_if_suceeded
        #echo "fastest mirror selected"

#install the base syste & linux kernel.
pacstrap /mnt base
result=$? && check_if_suceeded
echo "base system installed to /mnt"

#using UUID for fstab
genfstab -U /mnt > /mnt/etc/fstab
result=$? && check_if_suceeded
echo "fstab created"

echo "Installation Complete, manual intevension required now"
echo "Time to chroot"
exit()
