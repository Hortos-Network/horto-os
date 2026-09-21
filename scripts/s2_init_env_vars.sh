#!/bin/sh
set -eu
# Step 2: configure persistent environment variables for the Horto OS setup.

case "${0##*/}" in
  sh|dash|bash)
    echo "Error: do not source this script. Run it with 'sh s2_init_env_vars.sh' or './s2_init_env_vars.sh'." >&2
    return 1 2>/dev/null || exit 1
    ;;
esac

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
ACTIVE_SETUP_DIR="/srv/active_setup"

OS_CONF_TEMPLATE_FILE="$REPO_ROOT/config/os-configuration.env"
OS_CONF_ACTIVE_FILE="$ACTIVE_SETUP_DIR/os-configuration.env"

SETUP_SCRIPT="$SCRIPT_DIR/helpers/s2_helper_script.sh"

mkdir -p "$ACTIVE_SETUP_DIR"

active_file="$OS_CONF_ACTIVE_FILE"
template_file="$OS_CONF_TEMPLATE_FILE"

if [ ! -f "$template_file" ]; then
  echo "Error: template file not found: $template_file" >&2
  exit 1
fi

if [ ! -f "$active_file" ]; then
  echo "Active variables file not found. Running setup first..."
  sh "$SETUP_SCRIPT"
fi

if [ ! -f "$active_file" ]; then
  echo "Error: active variables file still missing: $active_file" >&2
  exit 1
fi

# shellcheck disable=SC1090
. "$active_file"

required_vars="MY_HOSTNAME OS_TYPE NPU_TYPE INSTALL_TYP IOT_LAN"
for var_name in $required_vars; do
  eval "var_value=\${$var_name-}"
  if [ -z "$var_value" ]; then
    echo "Error: required variable $var_name is empty in $active_file" >&2
    exit 1
  fi
done

echo "Loaded full deployment variables from $active_file"
echo "  MY_HOSTNAME=$MY_HOSTNAME"
echo "  OS_TYPE=$OS_TYPE"
echo "  NPU_TYPE=$NPU_TYPE"
if [ -n "${RAM_SYZE:-}" ]; then
  echo "  RAM_SYZE is set"
else
  echo "  RAM_SYZE is empty"
fi
echo "  INSTALL_TYP=$INSTALL_TYP"
echo "  IOT_LAN=$IOT_LAN"
echo "  MY_URL=$MY_URL"

# If IOT-LAN is set to yes run s2_init_env_vars_iot.sh
if [ "$IOT_LAN" = "y" ]; then
  echo "IOT-LAN setup is next"
  sh "$SCRIPT_DIR/networking/s2_init_env_vars_iot.sh"
else
  echo "setup without IOT_LAN detected"
fi

echo "Step 2 complete: active variables are ready to check."
echo "Check file $active_file", especially the active ethernet interface names."
echo "Next step: run scripts/s3_backup_etc_configs.sh before deploying managed files from $REPO_ROOT/config into /etc."
