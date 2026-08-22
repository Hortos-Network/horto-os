# Horto-OS scripted setup

**Summary**: This guide describes the tested scripted setup flow for Horto-OS on a fresh RK3588-based system.

---

## Before you start

Make sure you already:

1. flashed and booted Armbian,
2. optionally copied the system to eMMC,
3. installed `git`,
4. cloned the repository into `/srv/horto-os`.

At this point the scripted setup begins.

## Scripted setup sequence

Run the scripts from `/srv/horto-os/scripts`.

> [!NOTE]
> The scripts are run in the order shown below.
There is a difference between the full IoT LAN setup and the minimal hostname-only setup.
In the minimal setup, only the hostname is configured (s1, s2_init_env_vars.sh plus s3_are run).
In the full IoT LAN setup, the hostname is configured along with the WiFi
credentials and a DHCP server is installed.

### 1. Install required packages

```bash
sh s1_init_horto_os.sh
```

This installs the required host packages for the chosen setup path.

- The base packages are installed first.
- You can choose whether to install the IoT-LAN-specific packages too.

### 2. Create active variables

```bash
sh s2_init_env_vars.sh
```

This creates one of these files in `/srv/active_setup/`:

- `/srv/active_setup/my_variables.env` for the full IoT LAN setup
- `/srv/active_setup/my_hostname.env` for the minimal hostname-only setup

For the full setup, the script currently manages these variables:

```env
MY_HOSTNAME="Horto-OS_xxx"
WIFI_INTERFACE="wlx00xxxxxx"
WIFI_SSID="Horto-IoT-LAN"
WIFI_PASSPHRASE=""
MY_URL="YourDomainName.net"
```

> [!NOTE]
> `WAN_GATEWAY` is no longer managed. The WAN side should receive IP address, DNS, and default route dynamically via DHCP.

### 3. Create the protected initial backup

```bash
sh s3_backup_etc_configs.sh
```

This creates the protected initial backup under:

```text
/srv/backup/etc/initial_setup
```

Only the `/etc` files and directories corresponding to tracked items in `config/` are backed up.

### 4. Create additional timestamped backups when needed

```bash
sh timestamped_backup_etc_configs.sh
```

This creates a dated backup under:

```text
/srv/backup/etc/YYYYMMDD-HHMMSS
```

Use this before later changes or repeated testing.

### 5. Stage the rendered configuration

```bash
sh s4_deploy_configs.sh
```

This does **not** write directly into `/etc`.
Instead, it:

- copies static managed config files,
- renders placeholder-based templates,
- stages everything under `/srv/active_setup/etc`.

Review the staged files before applying them.

### 6. Apply the staged configuration

```bash
sh s5_apply_configs.sh
```

This copies the staged files from `/srv/active_setup/etc` into `/etc`.

### 7. Validate the applied configuration

```bash
sh s6_validate_configs.sh
```

This checks:

- expected files exist,
- no placeholders remain,
- `netplan generate` succeeds in the full setup.

### 8. Activate services and optional NAT rules

```bash
sh s7_activate_services.sh
```

This step:

- reloads `sysctl`,
- applies `netplan`,
- restarts `dnsmasq`, `hostapd`, and `avahi-daemon` if present,
- optionally adds the `iptables` NAT / masquerade rules,
- optionally installs `iptables-persistent`.

### 9. Reboot recommended

After the activation step, reboot the system:

```bash
sudo reboot
```

A reboot is strongly recommended after network-related changes.

## Docker source deployment

After the base host setup is working, initialize the Docker app data and stacks:

```bash
sh d1_docker_init.sh
```

This copies the full `docker_source/` tree into:

```text
/srv/docker/
```

and renders placeholders in the copied files there.

## Notes and decisions

### Resolver handling

In the IoT LAN setup, Horto-OS deploys a plain `/etc/resolv.conf` from the managed `config/resolv.conf` file.
The current tested resolver design uses:

```conf
nameserver 127.0.0.1
nameserver 9.9.9.9
```

This assumes the host uses the local `dnsmasq` instance for DNS and keeps a public resolver as fallback.

Do not switch `/etc/resolv.conf` to the `systemd-resolved` stub (`127.0.0.53`) in this setup when `dnsmasq` is already serving local DNS on the host.

### WAN uplink handling

The WAN uplink is now intentionally dynamic.
The netplan config should obtain:

- WAN IP address
- DNS
- default route

from DHCP.

This makes the setup more portable for cloned images and less technical users.


## Continue with Docker setup

After the host-side setup is complete, continue with:

- [Horto-OS setup 4 – Docker](Horto-OS_setup_4_docker.md)
- [Homepage (Dashboard)](Homepage%20%28Dashboard%29.md)
