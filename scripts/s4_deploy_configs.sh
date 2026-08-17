#!/bin/sh
set -eu
# Step 4: stage managed configuration files in /srv/active_setup/etc.

case "${0##*/}" in
  sh|dash|bash)
    echo "Error: do not source this script. Run it with 'sh s4_deploy_configs.sh' or './s4_deploy_configs.sh'." >&2
    return 1 2>/dev/null || exit 1
    ;;
esac

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
CONFIG_DIR="$REPO_ROOT/config"
ACTIVE_SETUP_DIR="/srv/active_setup"
STAGING_ETC_DIR="$ACTIVE_SETUP_DIR/etc"
FULL_ACTIVE_FILE="$ACTIVE_SETUP_DIR/my_variables.env"
MINIMAL_ACTIVE_FILE="$ACTIVE_SETUP_DIR/my_hostname.env"

if [ ! -d "$CONFIG_DIR" ]; then
  echo "Error: config directory not found: $CONFIG_DIR" >&2
  exit 1
fi

mkdir -p "$STAGING_ETC_DIR"

render_template() {
  template_path="$1"
  output_path="$2"

  cp "$template_path" "$output_path"

  for var_name in MY_HOSTNAME WIFI_INTERFACE WIFI_SSID WIFI_PASSPHRASE MY_URL; do
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

if [ -f "$FULL_ACTIVE_FILE" ]; then
  mode="full"
  # shellcheck disable=SC1090
  . "$FULL_ACTIVE_FILE"
elif [ -f "$MINIMAL_ACTIVE_FILE" ]; then
  mode="minimal"
  # shellcheck disable=SC1090
  . "$MINIMAL_ACTIVE_FILE"
else
  echo "Error: no active setup file found. Run s2_init_env_vars.sh first." >&2
  exit 1
fi

case "$mode" in
  full)
    required_vars="MY_HOSTNAME WIFI_INTERFACE WIFI_SSID"
    for var_name in $required_vars; do
      eval "var_value=\${$var_name-}"
      if [ -z "$var_value" ]; then
        echo "Error: required variable $var_name is empty in $FULL_ACTIVE_FILE" >&2
        exit 1
      fi
    done

    render_and_stage_file "hosts"
    render_and_stage_file "hostapd/hostapd.conf"
    render_and_stage_file "netplan/99-iot-lan.yaml"

    stage_static_file "resolv.conf"
    stage_static_file "dnsmasq.d/iot-lan.conf"
    stage_static_file "sysctl.d/packet_forwarding.conf"
    stage_static_file "avahi/avahi-daemon.conf"
    stage_static_file "avahi/hosts"
    ;;
  minimal)
    if [ -z "${MY_HOSTNAME:-}" ]; then
      echo "Error: MY_HOSTNAME is empty in $MINIMAL_ACTIVE_FILE" >&2
      exit 1
    fi

    render_and_stage_file "hosts"
    ;;
esac

echo "Step 4 complete: configuration staged in $STAGING_ETC_DIR using $mode mode."
echo "!!! Review the staged files there before copying them into /etc. by running s5_apply_configs.sh !!!"
