---
type: guide
title: "Horto-OS setup 2 – manual"
aliases:
  - setup2
  - manual setup
description: Manual Horto-OS setup path without using the scripted deployment flow.
source_refs:
  - config/
tags:
  - software
  - Horto-OS
timestamp: 2026-08-14T18:30:00
created: 2026-07-25T15:52:35
---
# Horto-OS manual setup 2

**Summary**: This guide describes the manual setup path for Horto-OS when you do not want to use the scripted deployment flow.

---

## Recommended preparation

Even for the manual path, keep the same directory layout:

```text
/srv/
├── horto-os/
├── active_setup/
└── backup/
```

## 1. Install required packages manually

At minimum install the packages you need for your desired setup.

Example:

```bash
sudo apt update
sudo apt install -y cockpit cockpit-networkmanager
```

> [!important]
> Horto-OS is designed to run with a dedicated IOT LAN - a separate Local Area
Network reserved for IOT devices. If your RK3588 board has only one Ethernet
port, or you don't want to run a separate LAN for the IOT devices,
you can install the stack without the networking part.
But be aware that you need to perform more configuration, as the Horto-OS is
designed to use an IOT LAN.
> 


**If you don't want to install the IOT LAN, you can continue here.**

For a minimal hostname-only setup:

```bash
mkdir -p /srv/active_setup
cp /srv/horto-os/config/my_hostname.env /srv/active_setup/
nano /srv/active_setup/my_hostname.env
```

Edit the `my_hostname.env` file to set your desired hostname.

Skip the IoT LAN setup and continue with:

- [Docker apps](Docker%20apps.md)
- [Homepage (Dashboard)](Homepage%20%28Dashboard%29.md)


**To install the IOT LAN, you can start with the networking setup.**

For the IoT LAN path you will need this packages:

```bash
sudo apt install -y hostapd dnsmasq avahi-daemon
```

## 2. Create a manual backup of managed `/etc` paths

Create the backup directory:

```bash
sudo mkdir -p /srv/backup/etc/manual_initial
```

Then copy the relevant `/etc` files and directories corresponding to the managed items in `/srv/horto-os/config`.

## 3. Create the active variables file

For the full setup:

```bash
mkdir -p /srv/active_setup
cp /srv/horto-os/config/my_variables.env /srv/active_setup/
```

Edit the file:

```bash
nano /srv/active_setup/my_variables.env
```

## 4. Apply the managed config files manually

The managed config templates and files are located under:

```text
/srv/horto-os/config/
```

For templated files, replace placeholders manually before copying them into `/etc`.

Typical templated files:

- `hosts`
- `hostapd/hostapd.conf`
- `netplan/99-iot-lan.yaml`

Typical static files:

- `dnsmasq.d/iot-lan.conf`
- `sysctl.d/packet_forwarding.conf`
- `avahi/avahi-daemon.conf`
- `avahi/hosts`
- `resolv.conf`

> [!IMPORTANT]
> In the IoT LAN setup, Horto-OS uses a plain `/etc/resolv.conf` with the local `dnsmasq` resolver on `127.0.0.1` and an upstream fallback resolver. Do not replace it with the `systemd-resolved` stub (`127.0.0.53`) while `dnsmasq` is serving local DNS on the host.

## 5. Apply and activate the network changes manually

Typical follow-up commands are:

```bash
sudo sysctl --system
sudo netplan generate
sudo netplan apply
sudo systemctl restart dnsmasq
sudo systemctl restart hostapd
sudo systemctl restart avahi-daemon
```

## 6. Continue with Docker setup

After the host-side setup is complete, continue with:

- [Horto-OS setup 4 – Docker](Horto-OS_setup_4_docker.md)
- [Homepage (Dashboard)](Homepage%20%28Dashboard%29.md)
