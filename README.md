---
created: 2026-08-11T15:21:01
timestamp: 2026-08-11T15:36:43
---

Horto OS is a decentralised, privacy-focused operating system designed for **Home Hubs** (the **Horto Box**). This repo contains a set of documentation, scripts, and managed configuration files to deploy a basic Horto OS stack on a fresh Armbian-based RK3588 system.


![[Sovereign_Garden_Nightcafe_v5_with_EV_and_power_connect_x2_control.avif]]


> [!NOTE]
> This project is in a early stage and not all the functionalities are yet present.
> Nevertheless it can already be used to run a Homelab focused on Home Energy Management and / or Home Automation.

**List of potential use cases in the current stage of development:**

- Developers who want to contribute to the project
- People who are interested in edge computing on RK3588 boards
- People who want to run Frigate NVR, evcc or Home Assistant on a powerfull ARM CPU with AI capabilites.

## What is Horto OS?

Horto OS is a decentralised, privacy-focused operating system designed for **Home Hubs** (the **Horto Box**). It's built upon a fork of the technical substrate provided by [Coasys](https://coasys.org/), aiming to resolve the fundamental tension between coherence and sovereignty in networked systems.

At its core, Horto OS runs on Armbian and integrates a variety of applications, connected through the NEXUS Layer.

More information about Horto OS: [What is Horto OS?](docs/What%20is%20Horto%20OS.md) and [[Vision]].

## What you get with Horto OS?

- **An IOT LAN**, which means your Horto-Box acts as a local Router and you can separate all your Smart Home devices from the rest of the your local network.
- An easy to manage Docker stack with a graphical UI (Dockge).
- All the necessary scripts and Docker compose files to install for instance evcc (evcc.io)
- All the necessary scripts and Docker compose files to install several AI models, as LLM, STT, TTS, YOLO
- A pre-configured Dashboard (Homepage Dasboard) to get easy access to the apps and monitor your Horto-Box.
- If your Horto-Box has sufficient RAM (16GB) you can also install Home Assistant and Frigate NVR.

![[Screenshot__Homepage-Dashboard_Draft.avif]]

## Requirements

- A RK3588 board with minimal 8 GB RAM.
- Minimum of 32GB of storage on the RK3588 board, eMMC or SSD
- The tools to flash a SD card.

For a more capable Horto-BOX we recommend to have 16GB RAM and minimal 128 GB of storage.
## Repository Structure

This `horto-os` repository contains the core components for deploying and managing Horto OS. When cloned to your target system (e.g., `/srv/horto-os`), it will have the following structure:

```
/srv/
├── horto-os/         <-- Git Repository (Pushed/Pulled from GitHub)
│   ├── config/       <-- Configuration templates (dnsmasq.conf.template, etc.)
│   ├── docker_source/<-- Full Docker stack for Dockge (needs to be copied)
│   ├── docs/         <-- Documentation
│   └── scripts/      <-- Setup and deployment scripts
├── docker/           <-- Machine-specific docker stack (Dockge etc.)
│   ├── dockge/       <-- Dockge app (compose.yaml)
│   ├── docker_repos/ <-- Docker repositories files (eg. rkvoice-stream)
├── active_setup/     <-- Machine-specific config & active .env (NOT in Git)
└── backup/           <-- Local system safety backups (NOT in Git)
```


**Explanation**

-   `config/`: Configuration templates (e.g., `dnsmasq.conf.template`, etc.).
-   `docker_source/`: Full Docker stack definitions and application data intended to be copied to your machine-specific Docker directory.
-   `docs/`: Comprehensive documentation and detailed step-by-step guides for installation and setup.
-   `scripts/`: Setup and deployment scripts. The current scripted host setup sequence is `s1_init_horto_os.sh` → `s2_init_env_vars.sh` → `s3_backup_etc_configs.sh` → `s4_deploy_configs.sh` → `s5_apply_configs.sh` → `s6_validate_configs.sh` → `s7_activate_services.sh`. Docker app-data initialization currently begins with `d1_docker_init.sh`.

## Getting Started

To deploy Horto OS on a fresh RK3588-based system, follow the setup guides in the `docs/` folder.

Here's a high-level overview of the main installation phases:

1.  **[Horto-OS setup 1](docs/Horto-OS_setup_1.md)**:
    *   Flash and boot Armbian.
    *   Optionally move the system to eMMC.
    *   Install `git` and clone the repository into `/srv/horto-os`.

2.  **Choose the setup path**:
    *   **[Manual path](docs/Horto-OS_setup_2_manual.md)** for manual editing and copying.
    *   **[Scripted path](docs/Horto-OS_setup_2_scripted.md)** for the tested host setup scripts.

3.  **Scripted host setup flow**:
    *   `scripts/s1_init_horto_os.sh`
    *   `scripts/s2_init_env_vars.sh`
    *   `scripts/s3_backup_etc_configs.sh`
    *   `scripts/s4_deploy_configs.sh`
    *   `scripts/s5_apply_configs.sh`
    *   `scripts/s6_validate_configs.sh`
    *   `scripts/s7_activate_services.sh`

4.  **Network Configuration reference**:
    *   Additional network explanations and NAT examples are in [Horto-OS setup 3 – networking](docs/Horto-OS_setup_3_networking.md).

5.  **Docker and dashboard setup**:
    *   How to install the full Docker stack.
    *   Deployment of Dockge for user-friendly management of containerized applications.
    *   Docker source/app-data initialization begins with `scripts/d1_docker_init.sh`.
    *   Steps to deploy other services like EVCC, Whisper (CV), and MMS (TTS) using Dockge.
    *   **[Detailed Guide: docs/Horto-OS_setup_4_docker.md](docs/Horto-OS_setup_4_docker.md)**

## Contributing

We welcome contributions to Horto OS! Please refer to the `docs/` folder for guidelines on how to contribute, report issues, or suggest enhancements.

## License

Unless otherwise stated, this repository is licensed under Apache-2.0.  
Some subdirectories may be licensed differently; see the local LICENSE files.