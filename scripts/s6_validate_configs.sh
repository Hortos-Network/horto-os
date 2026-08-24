#!/bin/sh
set -eu
# Step 6: validate applied configuration files in /etc.

case "${0##*/}" in
  sh|dash|bash)
    echo "Error: do not source this script. Run it with 'sh s6_validate_configs.sh' or './s6_validate_configs.sh'." >&2
    return 1 2>/dev/null || exit 1
    ;;
esac

FULL_ACTIVE_FILE="/srv/active_setup/my_variables.env"
if [ ! -f "$FULL_ACTIVE_FILE" ]; then
  echo "This script is only needed for a IOT-LAN Setup"
  exit 0
fi

ACTIVE_SETUP_DIR="/srv/active_setup"
TARGET_ROOT="/etc"
FAILED=0

check_file_exists() {
  path="$1"
  if [ -f "$path" ]; then
    echo "OK: file exists: $path"
  else
    echo "ERROR: missing file: $path" >&2
    FAILED=1
  fi
}

check_no_placeholders() {
  path="$1"
  if [ ! -f "$path" ]; then
    echo "ERROR: cannot validate missing file: $path" >&2
    FAILED=1
    return
  fi

  if grep -q '{{[A-Z0-9_][A-Z0-9_]*}}' "$path"; then
    echo "ERROR: unreplaced placeholder found in $path" >&2
    FAILED=1
  else
    echo "OK: no placeholders remain in $path"
  fi
}

check_file_exists "$TARGET_ROOT/hosts"
check_no_placeholders "$TARGET_ROOT/hosts"

check_file_exists "$TARGET_ROOT/netplan/99-iot-lan.yaml"
check_no_placeholders "$TARGET_ROOT/netplan/99-iot-lan.yaml"

check_file_exists "$TARGET_ROOT/hostapd/hostapd.conf"
check_no_placeholders "$TARGET_ROOT/hostapd/hostapd.conf"

check_file_exists "$TARGET_ROOT/avahi/avahi-daemon.conf"
check_file_exists "$TARGET_ROOT/avahi/hosts"
check_file_exists "$TARGET_ROOT/resolv.conf"
check_file_exists "$TARGET_ROOT/dnsmasq.d/iot-lan.conf"
check_file_exists "$TARGET_ROOT/sysctl.d/packet_forwarding.conf"

if command -v netplan >/dev/null 2>&1; then
  if netplan generate >/tmp/horto-netplan-validate.out 2>/tmp/horto-netplan-validate.err; then
    echo "OK: netplan generate succeeded"
  else
    echo "ERROR: netplan generate failed" >&2
    cat /tmp/horto-netplan-validate.err >&2
    FAILED=1
  fi
else
  echo "WARNING: netplan command not found; skipping netplan validation"
fi

if [ "$FAILED" -ne 0 ]; then
  echo "Step 6 failed: configuration validation found errors." >&2
  exit 1
fi

echo "Step 6 complete: configuration validation passed."

# Unmask / enable / start hostapd (required for IoT LAN)
echo "Enabling hostapd..."
sudo systemctl unmask hostapd || true
sudo systemctl enable hostapd || true
sudo systemctl start hostapd || true
