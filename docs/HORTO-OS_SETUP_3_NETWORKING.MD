# Horto-OS setup 3 – networking

**Summary**: Reference for the networking configuration used by the Horto-OS IoT LAN setup.

---

> [!WARNING]
> This networking layout is currently tested primarily on the [NanoPi R6S](Hardware/NanoPi%20R6S.md).
If your board has a different interface layout, adjust the config accordingly.

## Networking model

Horto-OS uses:

- one WAN interface with DHCP uplink,
- two bridged LAN ports for the IoT LAN,
- optional WiFi AP support through `hostapd`,
- `dnsmasq` for DHCP and DNS on the IoT LAN,
- `iptables` masquerading for internet access from the IoT LAN.

The WAN side is intentionally dynamic.
The host should obtain:

- WAN IP address
- DNS
- default route

via DHCP from the upstream router.

## Requirements

- If you intend to use WiFi for the IoT LAN, you will need to attach a Linux compatible WiFi USB
  stick to the board. Or if your board does have built-in WiFi, you can use this instead.

## Current managed Netplan config

File:

```text
/etc/netplan/99-iot-lan.yaml
```

Current managed content from `config/netplan/99-iot-lan.yaml`:

```yaml
# /etc/netplan/99-iot-lan.yaml
# attached WiFi USB sticks are handled via hostapd.conf
network:
  version: 2
  renderer: networkd
  ethernets:
    # WAN interface: Connects to your main home router, gets IP, DNS, and default route via DHCP
    wan:
      dhcp4: yes
      dhcp6: yes

    # LAN interfaces, which will be part of the bridge
    # No IP configuration here, as they are enslaved to the bridge
    lan1: {}
    lan2: {}

  bridges:
    # Bridge for your IoT LAN (wired and wireless)
    br0:
      interfaces:
        - lan1
        - lan2

      addresses:
        - 192.168.10.1/24 # Static IP for the NanoPi's IoT LAN interface
      nameservers:
        addresses:
          - 9.9.9.9 # Primary DNS server (e.g., Quad9)
          - 1.1.1.1 # Secondary DNS server (e.g., Cloudflare)
      parameters:
        stp: true # Spanning Tree Protocol, generally good for bridges
        forward-delay: 0 # Reduce delay for faster network convergence
```

### Apply and test

```bash
sudo netplan generate
sudo netplan apply
```

Check interfaces and routes:

```bash
ip a
ip r
```

## Current managed hostapd config

File:

```text
/etc/hostapd/hostapd.conf
```

Current managed content from `config/hostapd/hostapd.conf`:

```conf
#### Explicitly state the modern kernel driver
driver=nl80211

#### Your actual WiFi interface name
interface={{WIFI_INTERFACE}}

#### The bridge interface name
bridge=br0

#### Your desired WiFi network name
ssid={{WIFI_SSID}}

#### Wireless mode (g for 2.4GHz)
hw_mode=g

#### Ensure explicit multicast-to-unicast mapping is off if your driver struggles
ap_isolate=0

#### Use a strong WiFi password
wpa_passphrase={{WIFI_PASSPHRASE}}

#### WiFi channel
channel=6
wmm_enabled=1
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
```

> [!NOTE]
> This file is templated. The placeholders are rendered by the scripted setup before the file is applied to `/etc`.

## Current managed dnsmasq config

File:

```text
/etc/dnsmasq.d/iot-lan.conf
```

Current managed content from `config/dnsmasq.d/iot-lan.conf`:

```conf
# Listen only on the IoT LAN bridge interface
interface=br0

# Define the DHCP range for your IoT LAN
# Assign IPs from .100 to .200 for 12 hours
dhcp-range=192.168.10.100,192.168.10.200,12h

# Specify the gateway for DHCP clients (the NanoPi's IP on br0)
dhcp-option=3,192.168.10.1

# Specify DNS servers for DHCP clients
dhcp-option=6,9.9.9.9,1.1.1.1

# --- DHCP Reservations for Fixed IPs ---
# MAC address,Name,IP Adress
# Reserved IP for [[Energy Concierge]] etc. (04-09)
dhcp-host=ec:71:db:e0:9f:b6,horty1.local,192.168.10.4

# Example for a Solar Inverter/s (10-19)
# dhcp-host=AA:BB:CC:DD:EE:F1,solar_inverter1,192.168.10.10

# Example for an EV Charger
# dhcp-host=AA:BB:CC:DD:EE:F2,ev_charger1,192.168.10.20

# Example for a Heat Pump
# dhcp-host=AA:BB:CC:DD:EE:F3,heatpump1,192.168.10.30

# Example for a Home Assistant instance (40-49)
# dhcp-host=AA:BB:CC:DD:EE:F4,heatpump1,192.168.10.40

# Example for a Smart Home devices (50-59)
# dhcp-host=AA:BB:CC:DD:EE:F5,heatpump1,192.168.10.50

# Example for Security Cameras (60-69)
# dhcp-host=AA:BB:CC:DD:EE:F6,heatpump1,192.168.10.60
```

Restart after changes:

```bash
sudo systemctl restart dnsmasq
```

## Resolver note

In the IoT LAN setup, Horto-OS uses a managed plain `/etc/resolv.conf` from `config/resolv.conf`.
The tested content is:

```conf
# resolv.conf file for dnsmasq with IOT LAN
nameserver 127.0.0.1
nameserver 9.9.9.9
```

This assumes the host resolver should use the local `dnsmasq` instance first and a public fallback second.
Do not point `/etc/resolv.conf` to the `systemd-resolved` stub (`127.0.0.53`) in this setup, because that conflicts with the local DNS service design.

## Enable IPv4 forwarding

Managed file:

```text
/etc/sysctl.d/packet_forwarding.conf
```

Content:

```conf
net.ipv4.ip_forward=1
```

Apply it:

```bash
sudo sysctl --system
```

## NAT / masquerading

To allow the IoT LAN to reach the internet through the WAN uplink:

```bash
sudo iptables -t nat -A POSTROUTING -o wan -j MASQUERADE
sudo iptables -A FORWARD -i br0 -o wan -j ACCEPT
sudo iptables -A FORWARD -i wan -o br0 -m state --state RELATED,ESTABLISHED -j ACCEPT
```

To persist these rules across reboot, you can install:

```bash
sudo apt install iptables-persistent
```

The scripted setup can also apply these rules for you in `s7_activate_services.sh`.

## Continue

After networking is working, continue with:

- [HORTO-OS_SETUP_4_DOCKER](HORTO-OS_SETUP_4_DOCKER.MD)
- [HOMEPAGE_(DASHBOARD)](HOMEPAGE_(DASHBOARD).MD)
