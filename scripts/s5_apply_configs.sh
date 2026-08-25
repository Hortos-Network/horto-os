#!/bin/sh
set -eu
# Step 5: apply staged configuration files from /srv/active_setup/etc into /etc.

case "${0##*/}" in
  sh|dash|bash)
    echo "Error: do not source this script. Run it with 'sh s5_apply_configs.sh' or './s5_apply_configs.sh'." >&2
    return 1 2>/dev/null || exit 1
    ;;
esac

FULL_ACTIVE_FILE="/srv/active_setup/my_variables.env"
if [ ! -f "$FULL_ACTIVE_FILE" ]; then
  echo "This script is only needed for a IOT-LAN Setup"
  exit 0
fi

ACTIVE_SETUP_DIR="/srv/active_setup"
STAGING_ETC_DIR="$ACTIVE_SETUP_DIR/etc"
TARGET_ROOT="/etc"

if [ ! -d "$STAGING_ETC_DIR" ]; then
  echo "Error: staging directory not found: $STAGING_ETC_DIR" >&2
  echo "Run s4_deploy_configs.sh first." >&2
  exit 1
fi

apply_file() {
  staged_file="$1"
  rel_path=${staged_file#"$STAGING_ETC_DIR"/}
  target_file="$TARGET_ROOT/$rel_path"

  # Special handling for resolv.conf to avoid overwriting a symlink
  if [ "$rel_path" = "resolv.conf" ]; then
    # Remove the symlink if it exists
    if [ -L "$target_file" ]; then
      echo "Removing existing resolv.conf symlink..."
      sudo rm -f "$target_file"
    fi
    # Also remove the file if it exists (in case it's a regular file)
    if [ -f "$target_file" ]; then
      echo "Removing existing resolv.conf file..."
      sudo rm -f "$target_file"
    fi
  fi

  mkdir -p "$(dirname "$target_file")"
  cp "$staged_file" "$target_file"
  # Set proper ownership and permissions
  sudo chown root:root "$target_file"
  sudo chmod 644 "$target_file"
  echo "Applied file: $staged_file -> $target_file"
}

# Copy all files from staging directory
find "$STAGING_ETC_DIR" -type f | while IFS= read -r staged_file; do
  apply_file "$staged_file"
done

# Disable systemd-resolved, to free up port 53 for dnsmasq
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved

echo "Step 5 complete: staged configuration applied from $STAGING_ETC_DIR to $TARGET_ROOT."
echo ""
echo "The hostname has been updated. A reboot is required for the changes to take effect."
echo -n "Do you want to reboot now? [y/N]: " >&2
IFS= read -r reboot_choice || true
case "$reboot_choice" in
  y|Y)
    echo "Rebooting..."
    reboot
    ;;
  *)
    echo "Skipping reboot. Remember to reboot later to apply hostname changes before proceeding."
    ;;
esac
