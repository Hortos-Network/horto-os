#!/bin/bash
##### YOU NEED TO RUN THIS SCRIPT FROM A SDCARD
##### IT WON'T WORK IF YOU RUN IT FROM THE eMMC
# Copy the script to an SD card which has Armbian installed
# Makes a backup of the eMMC partition 1 using partclone
# mount sda5 change to the appropriate device
sudo mount /dev/sda5 /mnt/external
# start backup of eMMC partition 1
# if there are other partitions you need to add this here
sudo partclone.ext4 -c -s /dev/mmcblk0p1 | gzip -c > /mnt/external/horto-os/emmc_p1_backup_$(date +%Y%m%d).img.gz
