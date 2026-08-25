#!/bin/sh
set -eu
# Step 1: install the base packages required before configuration backup and deployment.

case "${0##*/}" in
  sh|dash|bash)
    echo "Error: do not source this script. Run it with 'sh s1_init_horto_os.sh' or './s1_init_horto_os.sh'." >&2
    return 1 2>/dev/null || exit 1
    ;;
esac

sudo apt update

# Install Cockpit, then add the network manager package.
sudo apt install -y cockpit cockpit-networkmanager

# Install additional packages used by the Horto OS setup for IoT LAN components.
echo "Installing IoT LAN components..."
sudo apt install -y hostapd dnsmasq iptables avahi-daemon

echo "Step 1 complete: base packages installed."
