#!/bin/sh
set -eu
# Step 5: apply staged configuration files from /srv/active_setup/etc into /etc.

case "${0##*/}" in
  sh|dash|bash)
    echo "Error: do not source this script. Run it with 'sh s5_apply_configs.sh' or './s5_apply_configs.sh'." >&2
    return 1 2>/dev/null || exit 1
    ;;
esac

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

  mkdir -p "$(dirname "$target_file")"
  cp "$staged_file" "$target_file"
  echo "Applied file: $staged_file -> $target_file"
}

find "$STAGING_ETC_DIR" -type f | while IFS= read -r staged_file; do
  apply_file "$staged_file"
done

echo "Step 5 complete: staged configuration applied from $STAGING_ETC_DIR to $TARGET_ROOT."
