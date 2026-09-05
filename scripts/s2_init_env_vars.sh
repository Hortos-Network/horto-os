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
FULL_TEMPLATE_FILE="$REPO_ROOT/config/my_variables.env"
FULL_ACTIVE_FILE="$ACTIVE_SETUP_DIR/my_variables.env"
SETUP_SCRIPT="$SCRIPT_DIR/s2_helper_script.sh"

mkdir -p "$ACTIVE_SETUP_DIR"

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

# Automatically discover physical ethernet interfaces based on connection state
ACTIVE_ETH=$(ip -o link show | awk -F': ' '$2 ~ /^en/ && /LOWER_UP/ {print $2}')

# Fallback: if none are actively linked, grab the first three 'en' interfaces alphabetically
if [ -z "$ACTIVE_ETH" ]; then
    ETH0=$(ip -o link show | awk -F': ' '$2 ~ /^en/ {print $2}' | head -n 1)
    ETH1=$(ip -o link show | awk -F': ' '$2 ~ /^en/ {print $2}' | tail -n +2 | head -n 1)
    ETH2=$(ip -o link show | awk -F': ' '$2 ~ /^en/ {print $2}' | tail -n +3 | head -n 1)
    : "${ETH0:=wan}"
    : "${ETH1:=lan1}"
    # ETH2 stays empty if not found — no default
else
    ETH0="$ACTIVE_ETH"
    ETH1=$(ip -o link show | awk -F': ' '$2 ~ /^en/ && $2 != "'"$ETH0"'" {print $2}' | head -n 1)
    ETH2=$(ip -o link show | awk -F': ' '$2 ~ /^en/ && $2 != "'"$ETH0"'" && $2 != "'"$ETH1"'" {print $2}' | head -n 1)
fi

# Write discovered interfaces to the active variables file
if [ -f "$active_file" ]; then
    sed -i "/^ETH_LAN=/c\ETH_LAN=$ETH0" "$active_file" 2>/dev/null || true
    sed -i "/^ETH_IOT1=/c\ETH_IOT1=$ETH1" "$active_file" 2>/dev/null || true
    if [ -n "$ETH2" ]; then
        sed -i "/^ETH_IOT2=/c\ETH_IOT2=$ETH2" "$active_file" 2>/dev/null || true
    fi
    grep -q "^ETH_LAN=" "$active_file" || echo "ETH_LAN=$ETH0" >> "$active_file"
    grep -q "^ETH_IOT1=" "$active_file" || echo "ETH_IOT1=$ETH1" >> "$active_file"
    if [ -n "$ETH2" ]; then
        grep -q "^ETH_IOT2=" "$active_file" || echo "ETH_IOT2=$ETH2" >> "$active_file"
    fi
else
    cat << EOF > "$active_file"
ETH_LAN=$ETH0
ETH_IOT1=$ETH1
EOF
    [ -n "$ETH2" ] && echo "ETH_IOT2=$ETH2" >> "$active_file"
fi

echo "Discovered and saved: ETH_LAN=$ETH0, ETH_IOT1=$ETH1, ETH_IOT2=${ETH2:-not-set} to $active_file"

echo "Step 2 complete: active variables are ready to check."
echo "Check file $active_file", especially the active ethernet interface names."
echo "Next step: run scripts/s3_backup_etc_configs.sh before deploying managed files from $REPO_ROOT/config into /etc."
