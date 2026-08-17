#!/bin/sh
set -eu
# Step 7: activate applied network-related configuration and optional NAT rules.

case "${0##*/}" in
  sh|dash|bash)
    echo "Error: do not source this script. Run it with 'sh s7_activate_services.sh' or './s7_activate_services.sh'." >&2
    return 1 2>/dev/null || exit 1
    ;;
esac

ACTIVE_SETUP_DIR="/srv/active_setup"
FULL_ACTIVE_FILE="$ACTIVE_SETUP_DIR/my_variables.env"
MINIMAL_ACTIVE_FILE="$ACTIVE_SETUP_DIR/my_hostname.env"

if [ -f "$FULL_ACTIVE_FILE" ]; then
  mode="full"
elif [ -f "$MINIMAL_ACTIVE_FILE" ]; then
  mode="minimal"
else
  echo "Error: no active setup file found in $ACTIVE_SETUP_DIR" >&2
  exit 1
fi

restart_service_if_present() {
  service_name="$1"
  if systemctl list-unit-files "$service_name.service" >/dev/null 2>&1; then
    echo "Restarting $service_name..."
    systemctl restart "$service_name"
    systemctl enable "$service_name" >/dev/null 2>&1 || true
    systemctl --no-pager --full status "$service_name" | sed -n '1,5p'
  else
    echo "Skipping $service_name: service not installed."
  fi
}

apply_nat_rules() {
  echo "Applying NAT / masquerade rules for interface 'wan'..."

  iptables -t nat -C POSTROUTING -o wan -j MASQUERADE 2>/dev/null || \
    iptables -t nat -A POSTROUTING -o wan -j MASQUERADE
  iptables -C FORWARD -i br0 -o wan -j ACCEPT 2>/dev/null || \
    iptables -A FORWARD -i br0 -o wan -j ACCEPT
  iptables -C FORWARD -i wan -o br0 -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || \
    iptables -A FORWARD -i wan -o br0 -m state --state RELATED,ESTABLISHED -j ACCEPT

  echo "Applied NAT / masquerade rules."

  printf "Install iptables-persistent to save these rules across reboot? [y/N]: " >&2
  IFS= read -r install_persistent || true
  case "$install_persistent" in
    y|Y)
      apt install -y iptables-persistent
      netfilter-persistent save
      echo "Saved iptables rules via iptables-persistent."
      ;;
    ""|n|N)
      echo "Skipping iptables-persistent installation."
      ;;
    *)
      echo "Invalid choice '$install_persistent'. Expected y or n." >&2
      exit 1
      ;;
  esac
}

echo "Reloading sysctl settings..."
sysctl --system

if command -v netplan >/dev/null 2>&1; then
  echo "Applying netplan configuration..."
  netplan generate
  netplan apply
else
  echo "Skipping netplan apply: netplan command not found."
fi

restart_service_if_present dnsmasq
restart_service_if_present hostapd
restart_service_if_present avahi-daemon

case "$mode" in
  full)
    printf "Apply NAT / masquerade iptables rules now? [y/N]: " >&2
    IFS= read -r apply_nat || true
    case "$apply_nat" in
      y|Y)
        apply_nat_rules
        ;;
      ""|n|N)
        echo "Skipping NAT / masquerade rule setup."
        ;;
      *)
        echo "Invalid choice '$apply_nat'. Expected y or n." >&2
        exit 1
        ;;
    esac
    ;;
  minimal)
    echo "Minimal mode: skipping IoT LAN service activation and NAT setup."
    ;;
esac

echo "Step 7 complete: applied configuration activated. A reboot is recommended, especially after network changes."
