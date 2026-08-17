#!/bin/sh
set -eu
# Step 3: create the protected initial backup of /etc files and directories listed in the repo config directory.

case "${0##*/}" in
  sh|dash|bash)
    echo "Error: do not source this script. Run it with 'sh s3_backup_etc_configs.sh' or './s3_backup_etc_configs.sh'." >&2
    return 1 2>/dev/null || exit 1
    ;;
esac

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
CONFIG_DIR="$REPO_ROOT/config"
SOURCE_ROOT="/etc"
BACKUP_ROOT="/srv/backup/etc/initial_setup"

if [ ! -d "$CONFIG_DIR" ]; then
  echo "Error: config directory not found: $CONFIG_DIR" >&2
  exit 1
fi

if [ ! -d "$SOURCE_ROOT" ]; then
  echo "Error: source directory not found: $SOURCE_ROOT" >&2
  exit 1
fi

mkdir -p "$BACKUP_ROOT"

copy_path() {
  rel_path="$1"

  case "$rel_path" in
    my_*.env)
      echo "Skipping control file from config/: $rel_path"
      return 0
      ;;
  esac

  src="$SOURCE_ROOT/$rel_path"
  dest="$BACKUP_ROOT/$rel_path"

  if [ ! -e "$src" ]; then
    echo "Skipping missing path: $src"
    return 0
  fi

  if [ -d "$src" ]; then
    mkdir -p "$dest"
    cp -a "$src/." "$dest/"
    echo "Backed up directory: $src -> $dest"
  else
    mkdir -p "$(dirname "$dest")"
    cp -a "$src" "$dest"
    echo "Backed up file: $src -> $dest"
  fi
}

for path in "$CONFIG_DIR"/*; do
  [ -e "$path" ] || continue
  rel_path=$(basename "$path")
  echo "Processing config entry: $rel_path"
  copy_path "$rel_path"
done

echo "Step 3 complete: protected initial backup completed from $SOURCE_ROOT to $BACKUP_ROOT using entries listed in $CONFIG_DIR"
