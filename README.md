[![Discord](https://img.shields.io/badge/Discord-Horto%20OS-5865F2?logo=discord&logoColor=white)](https://discord.gg/Hbxd6vv98v)

# DGI-OS

**DGI-OS** is a decentralised, privacy-focused operating system designed for **XINTEL-DGI nodes** or **Home Hubs** (the **DGI-Box**), primarily built upon our future NEXUS framework, which is a Energy Managment in Rust. NEXUS is connected to the Adam Layer provided by [**Coasys**](https://coasys.org/), which allows inter node communication and data exchange. The architecture is designed to resolve the fundamental tension in networked systems between **coherence** (the ability to align and act as one) and **sovereignty** (the freedom of participants to remain independent).

The underlying Operation System can be any Debian/Ubuntu or Armbian OS. The apps
either run on DGI Nexus framework, or as Docker apps.

Basically DGI-OS can be deployed in different "flavors", corresponding to the
different use cases. There are three main use cases or deployment profiles:

## Deployment Profiles

|     | Deployment Profile | Managed Status | Description & Role |
| --- | ------------------ | -------------- | ------------------------------------------------------------- |
| 1st | **DGI-Hub Node** *(XINTEL-DGI Server)* | Fully Managed | Industrial Mini Server anchoring the wider XINTEL-DGI network. |
| 2nd | **DGI-Sat Node** *(DGI Satellite)* | Fully Managed | Edge nodes deployed as satellites connected upstream to a Core Node. |
| 3rd | **DGI-Home** *(HEMS)* | Partially Managed | Residential or SME deployment acting as an independent Home Energy Management System (HEMS). |

> [!NOTE]
> This project is in an early stage and only basic functionalities are present yet.
> DGI-Hub and DGI-Sat deployments are not yet implemented.
> Nevertheless, it can already be used to run a Homelab focused on Home Energy Management and / or Home Automation.

**List of potential use cases in the current stage of development:**

- Developers who want to contribute to the project

This use cases are related on using RK3576/3588 boards!

- People who are interested in edge computing on RK3576/3588 boards
- People who want to run [Frigate NVR](docs/apps/FRIGATE_NVR.md), evcc or Home
  Assistant on a powerfull ARM CPU with AI capabilites.
- DGI-OS comes with a fully Home Assistant compatible local AI stack (voice
  pipeline, AI inference)


More information about DGI-OS: [WHAT IS DGI-OS?](docs/WHAT_IS_DGI-OS.MD)
and [VISION](docs/VISION.MD).

## What can you get with DGI-OS?

- **An IOT LAN**, which means your DGI-Box acts as a local Router and you can separate all your Smart Home devices from the rest of the your local network.
- An easy to manage Docker stack with a graphical UI (Dockge).
- All the necessary scripts and Docker compose files to install for instance evcc (evcc.io)
- All the necessary scripts and Docker compose files to install several AI models, as LLM, STT, TTS
- A pre-configured Dashboard (Homepage Dasboard) to get easy access to the apps and monitor your DGI-Box.
- If your DGI-Box has sufficient RAM (16GB) you can also run larger AI models, as the provided DeepSeek 1.7b model.

![Dashboard](_assets/Screenshot_Homepage-Dashboard_Draft.avif)

## Requirements for RK3576/3588 boards

- A RK3588 board with minimal 8 GB RAM.
- Minimum of 64GB of storage on the RK3588 board, eMMC or SSD
- The tools to flash a SD card.

For a more capable DGI-Box we recommend to have 16GB RAM and minimal 128 GB of storage.

## Repository Structure

This `dgi-os` repository contains the core components for deploying and managing DGI-OS. When cloned to your target system (e.g., `/srv/dgi-os`), it will have the following structure:

```Text
/srv/
├── dgi-os/         <-- Git Repository (Pushed/Pulled from GitHub)
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

- `config/`: Configuration templates (e.g., `dnsmasq.conf.template`, etc.).
- `docker_source/`: Full Docker stack definitions and application data intended to be copied to your machine-specific Docker directory.
- `docs/`: Comprehensive documentation and detailed step-by-step guides for installation and setup.
- `scripts/`: Setup and deployment scripts. The current scripted host setup sequence is `s1_init_dgi_os.sh` → `s2_init_env_vars.sh` → `s3_backup_etc_configs.sh` → `networking/s4_deploy_configs.sh` → `networking/s5_apply_configs.sh` → `networking/s6_validate_configs.sh` → `networking/s7_activate_services.sh`. Docker app-data initialization currently begins with `d1_docker_init.sh`.

## Getting Started

To deploy DGI-OS on a fresh RK3588-based system, follow the setup guides in the `docs/` folder.

Here's a high-level overview of the main installation phases:

1. **[DGI-OS_SETUP_1](docs/DGI-OS_SETUP_1.MD)**:

   * Flash and boot Armbian.
   * Optionally move the system to eMMC.
   * Install `git` and clone the repository into `/srv/dgi-os`.

2. **Choose the setup path**:

   * **[MANUAL PATH](docs/DGI-OS_SETUP_2_MANUAL.MD)** for manual editing and copying.
   * **[SCRIPTED PATH](docs/DGI-OS_SETUP_2_SCRIPTED.MD)** for the tested host setup scripts.


3. **Network Configuration reference**:
   
   * Additional network explanations and NAT examples are in [DGI-OS_SETUP_3 NETWORKING](docs/DGI-OS_SETUP_3_NETWORKING.MD).

4. **Docker and dashboard setup**:
   
   * How to install the full Docker stack.
   * Deployment of Dockge for user-friendly management of containerized applications.
   * Docker source/app-data initialization begins with `scripts/d1_docker_init.sh`.
   * Steps to deploy other services like EVCC, Whisper (CV), and MMS (TTS) using Dockge.
   * **[DGI-OS_SETUP_4 DOCKER](docs/DGI-OS_SETUP_4_DOCKER.MD)**

## Contributing

We welcome contributions to DGI-OS! Please refer to the `CONTRIBUTING.md` file for guidelines on how to contribute, report issues, or suggest enhancements.

## Known Issues

- The scripted host setup flow may not work on all platforms.
- The minimal SETUP flow is not extensifly tested and may need some adjustments.
- The Docker container 'yolo-detection' has been removed, due to performance issues.


## License

Unless otherwise stated, this repository is licensed under Apache-2.0.  
Some subdirectories may be licensed differently; see the local LICENSE files.

## Acknowledgments

DGI-OS is developed by XINTEL and uses ideas or apps/libraries from:

- Coasys [Github](https://github.com/Coasys)
- Holochain [Github](https://github.com/holochain)
- [evcc.io](https://evcc.io/) (Home Energy Management)
- [Wyoming Protocol](https://github.com/OHF-Voice/wyoming.git) (AI Voice Pipeline)
