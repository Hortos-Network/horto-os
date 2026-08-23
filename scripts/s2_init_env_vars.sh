#!/bin/sh
set -eu
# Step 2: configure persistent environment variables for the Horto OS setup.

case "${0##*/}" in
  sh|dash|bash)
    echo "Error: do not source this script. Run it with 'sh s2_init_env_vars.sh' or './s2_init_env_vars.sh'." >&2
    return 1 2>/dev/null || exit 1
    ;;
esac
# For the standard IoT LAN setup, store the full variable set in "/srv/active_setup/my_variables.env".

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
ACTIVE_SETUP_DIR="/srv/active_setup"
FULL_TEMPLATE_FILE="$REPO_ROOT/config/my_variables.env"
FULL_ACTIVE_FILE="$ACTIVE_SETUP_DIR/my_variables.env"
SETUP_SCRIPT="$SCRIPT_DIR/s2_helper_script.sh"

mkdir -p "$ACTIVE_SETUP_DIR"

# Full IoT LAN setup only
active_file="$FULL_ACTIVE_FILE"
template_file="$FULL_TEMPLATE_FILE"

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

required_vars="MY_HOSTNAME WIFI_INTERFACE WIFI_SSID"
for var_name in $required_vars; do
  eval "var_value=\${$var_name-}"
  if [ -z "$var_value" ]; then
    echo "Error: required variable $var_name is empty in $active_file" >&2
    exit 1
  fi
done

echo "Loaded full deployment variables from $active_file"
echo "  MY_HOSTNAME=$MY_HOSTNAME"
echo "  WIFI_INTERFACE=$WIFI_INTERFACE"
echo "  WIFI_SSID=$WIFI_SSID"
if [ -n "${WIFI_PASSPHRASE:-}" ]; then
  echo "  WIFI_PASSPHRASE is set"
else
  echo "  WIFI_PASSPHRASE is empty"
fi

echo "Step 2 complete: active variables are ready."
echo "Next step: run scripts/s3_backup_etc_configs.sh before deploying managed files from $REPO_ROOT/config into /etc."
