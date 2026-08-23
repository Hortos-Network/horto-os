# Horto-OS scripted setup for minimal hostname-only setup

**Summary**: This guide describes the tested scripted setup flow for Horto-OS on
a fresh RK3588-based system with a minimal hostname-only setup.

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
For the IoT-LAN setup go to
[Horto-OS_setup_2_scripted.md](Horto-OS_setup_2_scripted.md) and follow the guide.


### 1. Installs required packages and sets up the minimal hostname-only setup

```bash
sh m1_minimal_setup_run.sh
```


#### 1.1 The base packages are installed first

#### 1.2 Active setup file gets generated

This creates a file in `/srv/active_setup/`:

- `/srv/active_setup/minimal_setup_vars.env` for the minimal hostname-only setup

For the minimal setup, the script currently manages these variables:

```env
MY_HOSTNAME="Horto-OS_xxx"
```

#### 1.3 Creates the protected initial backup

Finally it runs the script to create a protected initial backup of `/etc` under `/srv/backup/etc/initial_setup`:


### 2. Stage the rendered configuration

```bash
sh s4_deploy_configs.sh
```

This does **not** write directly into `/etc`.
Instead, it:

- copies static managed config files,
- renders placeholder-based templates,
- stages everything under `/srv/active_setup/etc`.

Review the staged files before applying them.

### 3. Apply the staged configuration

You need to manually copy the staged hosts file from `/srv/active_setup/etc` into `/etc`.

```bash
cp -r /srv/active_setup/etc/hosts /etc/
```

## Continue with Docker setup

After the host-side setup is complete, continue with:

- [Horto-OS setup 4 – Docker](Horto-OS_setup_4_docker.md)
- [Homepage (Dashboard)](Homepage%20%28Dashboard%29.md)
