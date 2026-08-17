# Backup your Horto-OS

**Summary**: A concise step by step instruction how to back up Horto-OS on a RK3588 mini PC.

**Sources**: Gemini

---

## Step by Step Guide

#### Method 1: `dd` with Compression (e.g., `gzip`)

This method copies the entire raw disk but compresses it as it goes.

**Pros:**

- Very simple and universally available.
- Creates a complete image of the entire drive, including partition tables and boot sectors.

**Cons:**

- Copies *all* blocks, even empty ones, before compression.
- Compression can be CPU-intensive and take time.

**Steps:**

1. **Prepare a temporary boot medium:** Flash a fresh Armbian image onto a *different* SD card.

2. **Boot from the temporary medium:** Insert this temporary SD card into your NanoPi and boot from it. **Do NOT boot from the eMMC.**

3. **Connect an external storage device:** Plug in a USB hard drive or large USB stick where you want to save your backup image. Make sure it's mounted and you know its mount point (e.g., `/media/usb_drive`).

4. **Identify your drives:**

   ```bash
   lsblk
   ```

   - Your eMMC will likely be `/dev/mmcblk0`.
   - Your temporary boot SD card will likely be `/dev/mmcblk1`.
   - Your external USB drive will likely be `/dev/sda` or `/dev/sdb` (or similar).
     **⚠️ IMPORTANT: Double-check the device names carefully! Using the wrong device name with `dd` can lead to irreversible data loss.**

5. **Create the compressed image:**

   ```bash
   sudo dd if=/dev/mmcblk0 bs=4M status=progress | gzip > /path/to/your/external/drive/emmc_backup_$(date +%Y%m%d).img.gz
   ```

   - `if=/dev/mmcblk0`: Your eMMC drive (input).
   - `bs=4M`: Block size for faster reading.
   - `status=progress`: Shows progress (may not be available on all `dd` versions).
   - `| gzip`: Pipes the output of `dd` directly to `gzip` for compression.
   - `> /path/to/your/external/drive/emmc_backup_$(date +%Y%m%d).img.gz`: Saves the compressed output to your external drive with a timestamped filename. **Replace `/path/to/your/external/drive/` with the actual path to your mounted external drive.**

**To restore the image:**

1. Boot from your temporary SD card again.

2. Identify your eMMC drive (`/dev/mmcblk0`).

3. Decompress and write the image back to the eMMC:

   ```bash
   sudo gzip -dc /path/to/your/external/drive/emmc_backup_YYYYMMDD.img.gz | dd of=/dev/mmcblk0 bs=4M status=progress
   ```

   - `gzip -dc`: Decompresses the `.gz` file and sends it to standard output.
   - `| dd of=/dev/mmcblk0`: Pipes the decompressed data to `dd` to write it to the eMMC.

------

#### Method 2: `partclone`

`partclone` is designed for cloning and restoring partitions. It's more efficient for backups as it only copies used blocks.

**Pros:**

- Copies only used blocks, resulting in smaller image files and faster backups.
- Supports various filesystems (ext4, btrfs, etc.).

**Cons:**

- Requires you to work with individual partitions, not the whole disk at once (though you can script it to do all partitions).
- Partitions must be unmounted before cloning.

**Steps:**

1. **Prepare temporary boot medium and external storage:** Same as for `dd`.

2. **Identify drives and partitions:**

   ```bash
   lsblk
   ```

   Note the partitions on your eMMC (e.g.,


   ```
   /dev/mmcblk0p1
   ```

3. **Reboot on SD card:**
Put the Armbian SD card into the NanoPi.
Then reboot.

   ```bash
   sudo reboot now
   ```

Check if you are running on the SD card now.

4. **Install `partclone`:**

   ```bash
   sudo apt update
   sudo apt install partclone
   ```

5. **Mount Backup partitions:** Before you can clone to a partition, it must be mounted.

Plug in your external USB drive.

   ```bash
   lsblk
   ```

   Note the partition you want to use.


1. **Create a mount point folder:**

```Bash
   sudo mkdir -p /mnt/external
```

2. **Mount the partition (`sda5`):**

If it's an ext4/Linux filesystem:

```Bash
sudo mount /dev/sda5 /mnt/external
```


6. **Create compressed image of a partition:**

In the case you have a folder folder `horto-os`

```bash
sudo partclone.ext4 -c -s /dev/mmcblk0p1 | gzip -c > /mnt/external/horto-os/emmc_p1_backup_$(date +%Y%m%d).img.gz
```

   - `partclone.ext4`: Use the specific `partclone` command for your filesystem type (e.g., `partclone.ext4` for ext4, `partclone.btrfs` for btrfs).
   - `-c`: Create image.
   - `-s /dev/mmcblk0p1`: Source partition.
   - `| gzip -c`: Pipes output to `gzip` for compression.
   - `> /path/to/your/external/drive/emmc_p1_backup_$(date +%Y%m%d).img.gz`: Destination file.
   - **Repeat this for all partitions on your eMMC.**

If you have downloaded the Horto-OS repo into `/srv`, you can use the included helper script for a `partclone` backup. You may still need to adapt the paths to your environment.

```bash
sh /srv/horto-os/scripts/partclone_backup_sda5.sh
```

### About the Boot Sector?

Because you are working with an ARM Rockchip board (like the [NanoPi R6S](Hardware/NanoPi%20R6S.md)) rather than an x86 PC:

No Traditional MBR/BIOS: Rockchip SoCs do not store bootloaders in a standard Master Boot Record (MBR) at sector 0. Instead, the primary bootloader code (SPL/U-Boot) is flashed to specific offset sectors right at the very beginning of the raw disk (usually starting around sector 64 or 32k) before the first partition begins.

What your current backup misses: Since your partclone.ext4 command only targets mmcblk0p1 (the first partition), it does not back up the raw bootloader blocks residing outside of that partition.
How to handle the boot sector for deployment: To make a truly standalone bootable image for eMMC boards, you should also dump the raw partition table and the initial boot sectors of the disk layout using dd:

```Bash
sudo dd if=/dev/mmcblk0 of=/mnt/external/horto-os/emmc_bootsectors_backup.img bs=1M count=4
```

When deploying to a new board, you write those boot sectors back to the target disk first, create your 32GB target partition structure, and then restore your partclone image into


### **To restore a partition image:**

1. Boot from your temporary SD card.

2. Identify your eMMC drive and its partitions.

3. **Important:** You might need to recreate the partition table on the eMMC first if it's completely blank or corrupted. Use `fdisk` or `gparted` for this. Ensure the new partitions are the same size or larger than the original ones.

4. Decompress and restore the image to the partition:

```bash
sudo gzip -dc /mnt/external/horto-os/emmc_p1_backup_YYYYMMDD.img.gz | partclone.ext4 -r -o /dev/mmcblk0p1
```

   - `-r`: Restore image.
   - `-o /dev/mmcblk0p1`: Output (target) partition.

------

For frequent snapshots, `partclone` is generally more efficient due to its block-level copying. However, `dd` with compression is simpler if you just want a full disk image without worrying about individual partitions. Choose the method that best fits your comfort level and specific needs.


#### Method 3: shrink-backup (Backup to img files)

There is also a more universal method for backing up SBCs into small image files, largely independent of the operating system in use.

**shrink-backup** is a very fast utility for backing up your SBC:s into minimal bootable img files for easy restore with autoexpansion at boot.

Can backup any device with or without a boot partition as long as the filesystem is ext4, f2fs or btrfs (with subvolumes).

Supports backing up root & boot (if existing) partitions. Data from other partitions will be written to root if not excluded.
For btrfs, all existing top level 5 subvolumes in /etc/fstab will be created with new backups, nested subvolumes will be created and can also be removed/added in an update of the backup img.
Please read Info section for more information.

Autoexpansion tested & supported on following operating systems:

```text
Raspberry Pi OS (trixie and older)
Armbian
Manjaro-arm
DietPi
ArchLinuxArm
Kali-arm
Ubuntu-server-arm (Ubuntu autoexpands by default, but that can be disabled with -e option)
```

Ref: [github.com/UnconnectedBedna/shrink-backup](https://github.com/UnconnectedBedna/shrink-backup)
## Related Topics

- 