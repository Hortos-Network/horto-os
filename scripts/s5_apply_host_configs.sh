#!/bin/sh
set -eu
# Step 5: apply basic host configuration files from staging to /etc.

case "${0##*/}" in
  sh|dash|bash)
    echo "Error: do not source this script. Run it with 'sh s5_apply_host_configs.sh' or './s5_apply_host_configs.sh'." >&2
    return 1 2>/dev/null || exit 1
    ;;
esac

ACTIVE_SETUP_DIR="/srv/active_setup"
STAGING_ETC_DIR="$ACTIVE_SETUP_DIR/etc"
TARGET_ROOT="/etc"

if [ ! -f "$STAGING_ETC_DIR/hosts" ]; then
  echo "Error: staged hosts file not found: $STAGING_ETC_DIR/hosts"
  exit 1
fi

if [ ! -f "$STAGING_ETC_DIR/hostname" ]; then
  echo "Error: staged hostname file not found: $STAGING_ETC_DIR/hostname"
  exit 1
fi

# Apply hosts file
cp "$STAGING_ETC_DIR/hosts" "$TARGET_ROOT/hosts"
sudo chown root:root "$TARGET_ROOT/hosts"
sudo chmod 644 "$TARGET_ROOT/hosts"
echo "Applied: $STAGING_ETC_DIR/hosts -> $TARGET_ROOT/hosts"

# Apply hostname file
cp "$STAGING_ETC_DIR/hostname" "$TARGET_ROOT/hostname"
sudo chown root:root "$TARGET_ROOT/hostname"
sudo chmod 644 "$TARGET_ROOT/hostname"
echo "Applied: $STAGING_ETC_DIR/hostname -> $TARGET_ROOT/hostname"

echo "Step 5 complete: basic host configs applied."
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
