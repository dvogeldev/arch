
Automated Arch Linux root btrfs install within a LUKS encrypted drive
====================================================================

This script assumes you want to install this system in to /dev/sda. 
It does not prompt for comfirmation prior to proceeding.

Technically, it should work on any EFI device which covers most. 
For systems that use LEGACY boot, this script will not work.

Using this script is simple.
  First a user may boot into the Arch ISO, and 1.sh.
  After the 1.sh is complete, change root to /mnt and run 2.sh.

I've made few mandatory choices to make this install automated. 

- The script uses systemd boot. GRUB bootloader might have higher features,
  but systemd is faster.
