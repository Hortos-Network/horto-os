# HORTO-OS Dependencies

**Summary**: This document lists the dependencies required for different setup paths to run HORTO-OS. It is provided as a work in progress, as the mayority of the setup process is still being developed.

The dependencies are basically defined by the setup, and how you define these variables:

```
OS\\\_TYPE="debian" \\\# debian/armbian select    
NPU\\\_TYPE="rkRK3588" \\\# rkRK3576/rkRK3588/ select    
RAM\\\_SYZE="8gb"    
INSTALL\\\_TYP="hems" \\\# (hems,sat,hortex)    
IOT\\\_LAN="y/n" \\\# if Yes the setup will create an independent IOT\\\_LAN    
MY\\\_HOSTNAME="Horto-OS\\\_xxx"    
MY\\\_URL="YourDomainName.net"    
MY\\\_CLOUDFLARE\\\_TOKEN=""
```

## 1. Dependencies by Deployment Profile

HORTO-OS can be deployed in different flavors, corresponding to the different use cases. There are three main use cases:

| Deployment Profile | Core node | (HORTEX) | **Satellite Node** |
| - | - | - | :-: |
| **Selection \>** | hortex | sat | hems |
| **Hardware** | Mini Server | Edge node | Edge node |
| **Managed** | yes | yes | partially |
| **Packages** | NEXUS/HORTEX setup (tbd) | NEXUS/Sat setup (tbd) | NEXUS/HEMS setup (tbd), Docker |
| **Remark** | A node in the HORTEX network | Satellites connected to a HORTEX node | HEMS system for households or SME's |


## 2. Dependencies by OS Type

Depending on the type of the underlying operation system NEXUS and ADAM Layer packages require to be compiled accordingly.

| OS Type | Debian/Ubuntu (x86\_64) | Armbian (aarch64) |
| - | - | - |
| **Selection \>** | Debian | armbian |
| **OS related** | to define | to define |
| **NEXUS** | x86\_64 compiled | aarch64 compile |
| **ADAM Layer** | x86\_64 compiled | aarch64 compile |


## 3. Dependencies by NPU/GPU Type

Depending on the type of the installed Neural or Graphic Processing Unit different AI models are being deployed.

| NPU/GPU Type | **Selection** | Package (Docker) |
| - | :-: | - |
| **Rockchip RK3588** | rk3588 | rk3588-qwen3, rk3588-whisper |
| **Rockchip RK3576** | rk3576 | rk3576-qwen3, rk3576-whisper |
| **No NPU/GPU** | none | CPU models |


## 4. `Dependencies by IOT-LAN install process`

If IOT\_LAN is set to yes the setup will create an dedicated IOT-LAN.

The following packages will be installed by the setup scripts:

hostapd, dnsmasq, iptables, avahi-daemon

