cryptsetup open /dev/disk/by-partlabel/cryptsystem system
cryptsetup open --type plain --key-file /dev/urandom /dev/disk/by-partlabel/cryptswap swap
o=defaults,x-mount.mkdir
o_btrfs=$o,compress=lzo,ssd,noatime,space_cache,!!!noatime


mount -t btrfs -o subvol=@,$o_btrfs LABEL=system /mnt
mkdir /mnt/{boot,var,home,.snapshots}
mount -t btrfs -o subvol=@var,$o_btrfs LABEL=system /mnt/var
mount -t btrfs -o subvol=@home,$o_btrfs LABEL=system /mnt/home
mount -t btrfs -o subvol=@snapshots,$o_btrfs LABEL=system /mnt/.snapshots

mount LABEL=EFI /mnt/boot
