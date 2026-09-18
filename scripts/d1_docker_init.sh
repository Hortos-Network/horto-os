#!/bin/sh
set -eu
# Docker step 1: copy the full docker_source tree into /srv/docker and render placeholders there.

case "${0##*/}" in
  sh|dash|bash)
    echo "Error: do not source this script. Run it with 'sh d1_docker_init.sh' or './d1_docker_init.sh'." >&2
    return 1 2>/dev/null || exit 1
    ;;
esac

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
SOURCE_DIR="$REPO_ROOT/docker_source"
SOURCE_DIR_STACK="$REPO_ROOT/docker_source/stacks"
TARGET_DIR="/srv/docker/"
ACTIVE_SETUP_DIR="/srv/active_setup"
FULL_ACTIVE_FILE="$ACTIVE_SETUP_DIR/my_variables.env"
OS_CONF_FILE="$ACTIVE_SETUP_DIR/os-configuration.env"
MINIMAL_ACTIVE_FILE="$ACTIVE_SETUP_DIR/minimal_setup_vars.env"

if [ ! -d "$SOURCE_DIR" ]; then
  echo "Error: source directory not found: $SOURCE_DIR" >&2
  exit 1
fi

if [ -f "$IOT-LAN_ACTIVE_FILE" ]; then
  # shellcheck disable=SC1090
  . "$IOT-LAN_ACTIVE_FILE"
elif [ -f "$MINIMAL_ACTIVE_FILE" ]; then
  # shellcheck disable=SC1090
  . "$MINIMAL_ACTIVE_FILE"
else
  echo "Error: no active setup file found in $ACTIVE_SETUP_DIR" >&2
  echo "Run s2_init_env_vars.sh first." >&2
  exit 1
fi

# Copy Docker Compose stack into "$TARGET_DIR/" (exclude stacks/)
mkdir -p "$TARGET_DIR"
for item in "$SOURCE_DIR"/*; do
  [ "$(basename "$item")" = "stacks" ] && continue
  cp -a "$item" "$TARGET_DIR/"
done
echo "Copied docker source tree: $SOURCE_DIR -> $TARGET_DIR (excluded stacks/)"

# Copy Docker Common stack into "$TARGET_DIR/"
cp -a "$SOURCE_DIR_STACK/common"/." "$TARGET_DIR/"
echo "Copied docker source common: $SOURCE_DIR_STACK/common -> $TARGET_DIR"

# Copy Docker Compose AI (with NPU) stack into "$TARGET_DIR/"
if [ -f "$OS_CONF_FILE" ]; then
  # shellcheck disable=SC1090
  . "$OS_CONF_FILE"
  if [ "$NPU_TYPE" = "none" ]; then
    echo "No configuration for NPU/GPU in setup file found in $OS_CONF_FILE" >&2
  else
    cp -a "$SOURCE_DIR_STACK/$NPU_TYPE"/." "$TARGET_DIR/"
    echo "Copied docker source tree: $SOURCE_DIR_STACK/$NPU_TYPE -> $TARGET_DIR"
  fi
else
  echo "Error: no active OS-conf setup file found in $OS_CONF_FILE" >&2
  exit 1
fi


# Copy assets (Homepage images, filtered to homepage*)
ASSETS_SOURCE="$REPO_ROOT/_assets"
ASSETS_TARGET="/srv/docker/assets"
if [ -d "$ASSETS_SOURCE" ]; then
  mkdir -p "$ASSETS_TARGET"
  copied=0
  for asset in "$ASSETS_SOURCE"/homepage*; do
    [ -f "$asset" ] || continue
    cp -a "$asset" "$ASSETS_TARGET/"
    echo "Copied asset: $asset -> $ASSETS_TARGET/"
    copied=1
  done
  if [ "$copied" -eq 0 ]; then
    echo "No homepage* assets found in $ASSETS_SOURCE; skipping asset copy."
  else
    echo "Copied assets: $ASSETS_SOURCE/homepage* -> $ASSETS_TARGET"
  fi
else
  echo "Skipping assets: directory not found at $ASSETS_SOURCE"
fi

render_file_in_place() {
  file_path="$1"

  for var_name in MY_HOSTNAME WIFI_INTERFACE WIFI_SSID WIFI_PASSPHRASE MY_URL; do
    eval "var_value=\${$var_name-}"
    escaped_value=$(printf '%s' "$var_value" | sed 's/[\\&|]/\\&/g')
    sed -i "s|{{${var_name}}}|$escaped_value|g" "$file_path"
  done

  echo "Rendered placeholders in: $file_path"
}

find "$TARGET_DIR" -type f | while IFS= read -r file_path; do
  if grep -q '{{[A-Z0-9_][A-Z0-9_]*}}' "$file_path"; then
    render_file_in_place "$file_path"
  fi
done


echo "d1 complete: full docker source copied and rendered in $TARGET_DIR"
echo "Go back the Docker documentation file `HORTO-OS_SETUP_4_DOCKER`"
