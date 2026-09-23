#!/bin/sh
set -eu
# Step 4: stage managed configuration files in /srv/active_setup/etc.

case "${0##*/}" in
  sh|dash|bash)
    echo "Error: do not source this script. Run it with 'sh s4_deploy_configs.sh' or './s4_deploy_configs.sh'." >&2
    return 1 2>/dev/null || exit 1
    ;;
esac

SCRIPT_DIR="/srv/horto-os/scripts"
REPO_ROOT="/srv/horto-os"
CONFIG_DIR="$REPO_ROOT/config"
ACTIVE_SETUP_DIR="/srv/active_setup"
STAGING_ETC_DIR="$ACTIVE_SETUP_DIR/etc"
IOT_LAN_ACTIVE_FILE="$ACTIVE_SETUP_DIR/iot-lan_conf.env"

if [ ! -d "$CONFIG_DIR" ]; then
  echo "Error: config directory not found: $CONFIG_DIR" >&2
  exit 1
fi

mkdir -p "$STAGING_ETC_DIR"

render_template() {
  template_path="$1"
  output_path="$2"

  cp "$template_path" "$output_path"

  for var_name in WIFI_INTERFACE WIFI_SSID WIFI_PASSPHRASE ETH_LAN ETH_IOT1 ETH_IOT2; do
    eval "var_value=\${$var_name-}"
    escaped_value=$(printf '%s' "$var_value" | sed 's/[\\&|]/\\&/g')
    sed -i "s|{{${var_name}}}|$escaped_value|g" "$output_path"
  done
}

stage_static_file() {
  rel_path="$1"
  src="$CONFIG_DIR/$rel_path"
  dest="$STAGING_ETC_DIR/$rel_path"

  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  echo "Staged static file: $src -> $dest"
}

render_and_stage_file() {
  rel_path="$1"
  src="$CONFIG_DIR/$rel_path"
  dest="$STAGING_ETC_DIR/$rel_path"

  mkdir -p "$(dirname "$dest")"
  render_template "$src" "$dest"
  echo "Rendered and staged file: $src -> $dest"
}

if [ -f "$IOT_LAN_ACTIVE_FILE" ]; then
  # shellcheck disable=SC1090
  . "$IOT_LAN_ACTIVE_FILE"
else
  echo "Error: no active setup file found. Run networking/s2_init_env_vars_iot.sh first." >&2
  exit 1
fi

required_vars="WIFI_INTERFACE"
case "$(printf '%s' "${WIFI_INTERFACE:-}" | tr '[:upper:]' '[:lower:]')" in
  none|-|n|no|'') ;;
  *) required_vars="$required_vars WIFI_SSID" ;;
esac
for var_name in $required_vars; do
  eval "var_value=\${$var_name-}"
  if [ -z "$var_value" ]; then
    echo "Error: required variable $var_name is empty in $IOT_LAN_ACTIVE_FILE" >&2
    exit 1
  fi
done

case "$(printf '%s' "${WIFI_INTERFACE:-}" | tr '[:upper:]' '[:lower:]')" in
  none|-|n|no|'') echo "WIFI_INTERFACE=none; skipping hostapd staging" ;;
  *) render_and_stage_file "hostapd/hostapd.conf" ;;
esac
render_and_stage_file "netplan/99-iot-lan.yaml"

stage_static_file "resolv.conf"
stage_static_file "dnsmasq.d/iot-lan.conf"
stage_static_file "sysctl.d/packet_forwarding.conf"
stage_static_file "avahi/avahi-daemon.conf"
stage_static_file "avahi/hosts"

# Set minimal permissions for netplan files
chmod 640 "$STAGING_ETC_DIR/netplan/99-iot-lan.yaml"
chmod 640 "$STAGING_ETC_DIR/netplan"/*

echo "Step 4 complete: configuration staged in $STAGING_ETC_DIR for IOT_LAN mode."
echo "Review the changes in $STAGING_ETC_DIR/netplan/99-iot-lan.yaml to adjust the available interfaces."
echo "!!! Review the staged files there before copying them into /etc. by running networking/s5_apply_configs.sh !!!"
