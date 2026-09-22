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
OS_CONF_ACTIVE_FILE="$ACTIVE_SETUP_DIR/os-configuration.env"

if [ ! -d "$CONFIG_DIR" ]; then
  echo "Error: config directory not found: $CONFIG_DIR" >&2
  exit 1
fi

mkdir -p "$STAGING_ETC_DIR"

render_template() {
  template_path="$1"
  output_path="$2"

  cp "$template_path" "$output_path"

  for var_name in MY_HOSTNAME MY_URL OS_TYPE NPU_TYPE INSTALL_TYPE IOT_LAN; do
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

if [ -f "$OS_CONF_ACTIVE_FILE" ]; then
  # shellcheck disable=SC1090
  . "$OS_CONF_ACTIVE_FILE"
else
  echo "Error: no active setup file found. Run s2_init_env_vars.sh first." >&2
  exit 1
fi

required_vars="MY_HOSTNAME"
for var_name in $required_vars; do
  eval "var_value=\${$var_name-}"
  if [ -z "$var_value" ]; then
    echo "Error: required variable $var_name is empty in $OS_CONF_ACTIVE_FILE" >&2
    exit 1
  fi
done

render_and_stage_file "hosts"
render_and_stage_file "hostname"
stage_static_file "resolv.conf"

echo "Step 4 complete: basic configuration staged in $STAGING_ETC_DIR."
echo "Your basic setup is done."

# If IOT-LAN is set to yes run networking/s4_deploy_configs.sh
if [ "$IOT_LAN" = "y" ]; then
  echo "IOT-LAN setup is next"
  sh "$SCRIPT_DIR/networking/s4_deploy_configs.sh"
else
  echo "setup without IOT_LAN completed"
  echo "Applying host configs next"
  sh "$SCRIPT_DIR/networking/s5_apply_host_configs.sh"
fi
