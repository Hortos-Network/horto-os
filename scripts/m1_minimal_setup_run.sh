#!/bin/sh
set -eu
# Step 1: install the base packages required before configuration backup and deployment.
# Step 2: configure persistent environment variables for the Horto OS minimal setup.

case "${0##*/}" in
  sh|dash|bash)
    echo "Error: do not source this script. Run it with 'sh m1_minimal_setup_run.sh' or './m1_minimal_setup_run.sh'." >&2
    return 1 2>/dev/null || exit 1
    ;;
esac

# For a minimal non-IoT-LAN setup, store only the hostname in "/srv/active_setup/minimal_setup_vars.env".

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
ACTIVE_SETUP_DIR="/srv/active_setup"
MINIMAL_TEMPLATE_FILE="$REPO_ROOT/config/minimal_setup_vars.env"
MINIMAL_ACTIVE_FILE="$ACTIVE_SETUP_DIR/minimal_setup_vars.env"

# Ensure the active-setup directory exists
mkdir -p "$ACTIVE_SETUP_DIR"

sudo apt update

# Install Cockpit, then add the network manager package.
sudo apt install -y cockpit cockpit-networkmanager

active_file="$MINIMAL_ACTIVE_FILE"
template_file="$MINIMAL_TEMPLATE_FILE"

if [ ! -f "$template_file" ]; then
    echo "Error: template file not found: $template_file" >&2
    exit 1
fi

if [ ! -f "$active_file" ]; then
    cp "$template_file" "$active_file"
    echo "Created minimal active variables file: $active_file"
fi

# shellcheck disable=SC1090
. "$active_file"

printf "Device hostname [%s]: " "${MY_HOSTNAME:-Horto-OS_xxx}" >&2
IFS= read -r hostname_input || true
if [ -n "$hostname_input" ]; then
    MY_HOSTNAME="$hostname_input"
fi

if [ -z "${MY_HOSTNAME:-}" ]; then
    echo "Error: MY_HOSTNAME is empty in $active_file" >&2
    exit 1
fi

cat > "$active_file" <<EOF
MY_HOSTNAME="$MY_HOSTNAME"
EOF

echo "Loaded minimal deployment variables from $active_file"
echo "  MY_HOSTNAME=$MY_HOSTNAME"
echo "  Manual network configuration remains your responsibility in minimal mode."

echo "Step 2 complete: active variables are ready."
echo "Step 2 started: s3_backup_etc_configs"
sh "$SCRIPT_DIR/s3_backup_etc_configs.sh"

echo "Next step: check active_setup/minimal_setup_vars.env and run scripts/s4_deploy_managed_files.sh to deploy managed files"