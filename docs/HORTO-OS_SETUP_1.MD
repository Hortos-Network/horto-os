# Horto-OS setup 1

**Summary**: Prepare the RK3588 board, install the base OS, and clone the Horto-OS repository into `/srv/horto-os`.

---

## 1. Flash and boot Armbian

Before you start, make sure you have:

- a suitable power supply for the board,
- a reliable SD card,
- a way to flash the card from another computer.

We recommend using Armbian Imager.

Reference:
[docs.armbian.com/User-Guide_Getting-Started](https://docs.armbian.com/User-Guide_Getting-Started/)

## 2. Update and install git manually

Armbian upgrade is recommended to run first and acts differently than apt upgrade.
It will take a while to complete.

```bash
sudo armbian-upgrade
```

Before using the Horto-OS setup scripts, install `git` manually.
Without `git` you cannot clone the repository.

```bash
sudo apt update
sudo apt install -y git
```

## 3. Clone the repository into `/srv`

```bash
cd /srv
git clone https://github.com/Hortos-Network/horto-os.git
```

The resulting layout should look like this:

```text
/srv/
├── horto-os/         <-- Git repository
│   ├── config/       <-- Managed configuration templates and static files
│   ├── docker_source/ <-- Docker stacks and app data sources
│   ├── docs/         <-- Documentation
│   └── scripts/      <-- Setup and deployment scripts
├── active_setup/     <-- Machine-specific active configuration (created later)
└── backup/           <-- Local safety backups (created later)
```


## 4. Copy the system from SD card to eMMC

After first reboot you can move the installation to the internal eMMC or SSD.

> [!NOTE]
> You can do this step later in the process too. If your SD card is large enough
(min. 32GB) you can do the full install on the SD card, but we don't reccomend
running Horto-OS on SD cards.

```bash
sudo sudo armbian-install
# on less recent Armbian versions the command may be called `nand-sata-install`
```

![Armbian nand-sata-install screenshot](../_assets/Screenshot_Armbian_nand-sata-install.avif)

**Select Boot from eMMC - system on eMMC** You will be asked to erase and then
format the eMMC drive (choose ext4).

If you get storage-related errors, check the visible block devices:

```bash
lsblk
```

Then reboot the device and remove teh SD card before it boots again. Now it should automatically boot from the eMMC.

## 5. Choose the next setup path

After the repository exists in `/srv/horto-os`, continue with either:

- [HORTO-OS_SETUP_2_MANUAL](HORTO-OS_SETUP_2_MANUAL.MD)
- [HORTO-OS_SETUP_2_SCRIPTED](HORTO-OS_SETUP_2_SCRIPTED.MD)

Or in case you want a scripted setup without IOT-LAN:

- [HORTO-OS_SETUP_2_SCRIPTED_MINIMAL](HORTO-OS_SETUP_2_SCRIPTED_MINIMAL.MD)
