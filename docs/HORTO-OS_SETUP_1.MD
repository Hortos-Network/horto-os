# Horto-OS setup 1

**Summary**: Choose your setup path, clone the Horto-OS repository into `/srv/horto-os`.

---

## 1. Choose your setup path

If you have a Armbian based board start with [ARMBIAN_SETUP_1](docs/ARMBIAN_SETUP_1.MD)
For X86/AMD64 boards with Debian or Ubuntu continue here.

## 2. Install git

Before using the Horto-OS setup scripts, install `git` manually.
Without `git` you cannot clone the repository.

```bash
sudo apt update
sudo apt install -y git
```

## 3. Clone the repository into `/srv`

```bash
cd /srv
git clone https://github.com/Hortos-Network/horto-os
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

## 6. Choose the next setup path

After the repository exists in `/srv/horto-os`, continue with either:

- [HORTO-OS_SETUP_2_MANUAL](HORTO-OS_SETUP_2_MANUAL.MD)
- [HORTO-OS_SETUP_2_SCRIPTED](HORTO-OS_SETUP_2_SCRIPTED.MD)

Or in case you want a scripted setup without IOT-LAN:

- [HORTO-OS_SETUP_2_SCRIPTED_MINIMAL](HORTO-OS_SETUP_2_SCRIPTED_MINIMAL.MD)
