cryptsetup open /dev/nvme0n1p3 luks
sleep 3

mount -o subvol=@,ssd,compress=lzo,noatime,nodiratime /dev/mapper/luks /mnt
sleep 3
mkdir /mnt/{boot,home,var}

mount -o subvol=@home,ssd,compress=lzo,noatime,nodiratime /dev/mapper/luks /mnt/home

sleep 3
mount -o subvol=@var,ssd,compress=lzo,noatime,nodiratime /dev/mapper/luks /mnt/var

sleep 3
mount /dev/sda1 /mnt/boot

#HOOKS="base udev autodetect modconf block encrypt btrfs filesystems keyboard fsck"
