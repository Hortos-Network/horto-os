# Horto-OS setup 1

**Summary**: Prepare the RK3588 board, install the base OS, and clone the Horto-OS repository into `/srv/horto-os`.

---

## 1. Flash and boot Armbian

Before you start, make sure you have:

- a suitable power supply for the board,
- a reliable SD card,
- a way to flash the card from another computer.

We recommend using Armbian Imager. Use the minimal CLI image for your board. 

Reference:
[docs.armbian.com/User-Guide_Getting-Started](https://docs.armbian.com/User-Guide_Getting-Started/)

## 2. Update Armbian

Armbian upgrade is recommended to run first and acts differently than apt upgrade.
It will take a while to complete.

```bash
sudo armbian-upgrade
```

## 3. Copy the system from SD card to eMMC

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

**Select Boot from eMMC - system on eMMC** or **Select Boot from SSD - system on SSD**

You will be asked to erase and then format the eMMC/SSD drive (choose ext4).

Then reboot the device and remove the SD card before it boots again.
Now it should automatically boot from the eMMC/SSD.

## 4. Install rktop (optional)

RKtop is a system monitoring tool that will be used to monitor the device
including the NPU load.

```bash
apt install cargo
sudo cargo install rktop --locked
echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

## 5. Choose the next setup path

After the basic steps continue:

- [HORTO-OS_SETUP_1](docs/HORTO-OS_SETUP_1.MD)
