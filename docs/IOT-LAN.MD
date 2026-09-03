# Horto-OS IoT LAN Documentation

## 1. Why You Should Use an IoT LAN

An isolated or dedicated IoT Local Area Network (IoT LAN) is a foundational architecture choice for modern smart home deployments, especially in self-hosted, energy-conscious, and privacy-first environments like **Horto-OS**.

### Key Benefits

* **Enhanced Security & Isolation:** IoT devices (smart plugs, inverters, heat pumps, IP cameras and microcontrollers) are notoriously prone to vulnerabilities, lack regular firmware updates, or engage in telemetry phoning home. Segmenting them onto a dedicated VLAN or subnet ensures that even if an IoT device is compromised, it cannot reach your private computers, NAS storage, or sensitive personal data.
* **Network Stability & Traffic Shaping:** Smart home environments generate heavy multicast, broadcast, and telemetry chatter (MQTT, mDNS, ESPHome heartbeats). Isolating this traffic keeps it off your primary corporate/personal Wi-Fi bandwidth, preventing latency spikes on your main network.
* **Local-First Reliability:** An IoT LAN ensures that all smart automation loops—such as local MQTT brokers, Node-RED flows, Home Assistant local API calls, and energy management loops—run entirely on-premise without relying on the home Local LAN. If your Home Internet Router drops, your local energy orchestration and automations continue running seamlessly.

### Ethernet ports

Your RK3588 board does need at least two Ethernet ports, if you need wired connectivity. Usually the LAN1 or WAN port is used for the primary network connection, while the LAN2 or LANx port is used for the IoT LAN.


---

## 2. Requirements & Limitations

Implementing a robust IoT LAN requires careful planning regarding network gear, routing, and physical boundaries.

### Core Requirements

We only cover the built-in Horto-OS IOT-LAN router and DHCP server functionality here.

**Your RK3588 board does need at least two Ethernet ports, if you need wired connectivity.**

Some device as the [reComputer RK3588](Hardware/reComputer RK3588-30.md) have a built-in Wifi Adapter that can be used as an IoT LAN Wifi router. Other devices need a USB Wifi Adapter or an external IoT LAN router atached to a Ethernet port.

* **Built-in Horto-OS IOT-LAN Router:** The built-in router capable routing and DHCP server functionality (dedicated DHCP `dnsmasq`).
* **Router / Firewall with VLAN Support:** A router capable of multi-subnet routing, firewall rules (inter-VLAN routing controls), and DHCP server functionality (or a dedicated DHCP server like `dnsmasq`).
* **Managed Switches (if wired):** To carry multiple VLAN tags across physical Ethernet cables if your IoT devices span multiple physical locations.


### Handling Long-Distance Devices (e.g., HaLOW Wi-Fi / Remote Outbuildings)

In rural, agricultural, or expansive garden setups (such as monitoring remote solar arrays, water pumps, or outbuilding energy meters), standard Wi-Fi range is insufficient.

* **Dedicated Point-to-Point (P2P) Bridges:** Use bidirectional 2.4GHz or 5GHz wireless bridges (such as ANJIELO SMART products) to create an invisible Ethernet cable from your main technical room to the remote outbuilding.
* **Local Subnet Extension:** Terminate a IOT-LAN port into a local unmanaged switch or an isolated outdoor Access Point in the outbuilding. This makes remote devices appear as though they are physically plugged into your IoT LAN switch, allowing standard fixed DHCP reservations and local MQTT routing without signal degradation.

---

## 3. Configuring Fixed IPs, DNS, and mDNS on Horto-OS

To maintain absolute deterministic control over your IoT infrastructure, Horto-OS relies on a combination of **dnsmasq** for static DHCP leases and full domain name resolution, alongside **avahi-daemon** for local multicast name resolution (`.local`).

> [!note]
> When you did run a standard scripted setup, you may not need to manually
> configure all these settings. You need only to add your devices which require a static fixed IP address.
> The automatically issued DHCP leases you can easy find on the Homepage Dashboard.

### dnsmasq Configuration (`/etc/dnsmasq.d/iot-lan.conf` or equivalent block)

By enforcing fixed MAC-to-IP bindings and assigning explicit `.local` hostnames, your services and containers can communicate securely via human-readable names rather than eventually volatile IP addresses. But in this example they also get a fixed IP address.

```text
# --- DHCP Reservations for Fixed IPs ---
# Format: MAC address, Hostname/Domain, IP Address
# Reserved IP allocations for Horto-OS infrastructure and IoT nodes

# Core Home Automation & Concierge Nodes
dhcp-host=20:f8:3b:0a:67:90,home-assistant-voice.local,192.168.10.44
dhcp-host=98:03:8e:03:7c:6a,horty1.local,192.168.10.4
```

### Avahi Daemon Configuration (`/etc/avahi/avahi-daemon.conf`)

To ensure that `.local` hostnames resolve correctly across your network interfaces and that mDNS discovery packets propagate properly for devices and integrations (such as local cameras and ESPHome nodes), verify your Avahi reflector settings:

```ini
[server]
host-name=horto-os-gateway
domain-name=local
use-ipv4=yes
use-ipv6=yes
allow-interfaces=eth0,iot0

[reflector]
enable-reflector=yes
reflect-ipv=no
```

*Note: Enabling `enable-reflector` in Avahi allows multicast DNS packets to cross between your main network interface and your IoT LAN interface, ensuring Home Assistant discovers local devices instantly.*

#### Avahi HostsConfiguration (`/etc/avah/host`)

The Avahi hosts file defines static routes for IoT LAN devices, which needs to
be accessed through your Home Network. (The names need to be resolvable via DNSmasq)

```hosts
# Horto-OS static DHCP, see at dnsmasq.d/iot-lan.conf
192.168.10.4 horty1.local
192.168.10.44 home-assistant-voice.local
```
