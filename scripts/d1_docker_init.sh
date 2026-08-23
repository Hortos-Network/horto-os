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
SOURCE_DIR="$REPO_ROOT/docker_source/"
TARGET_DIR="/srv/docker/"
ACTIVE_SETUP_DIR="/srv/active_setup"
FULL_ACTIVE_FILE="$ACTIVE_SETUP_DIR/my_variables.env"
MINIMAL_ACTIVE_FILE="$ACTIVE_SETUP_DIR/minimal_setup_vars.env"

if [ ! -d "$SOURCE_DIR" ]; then
  echo "Error: source directory not found: $SOURCE_DIR" >&2
  exit 1
fi

if [ -f "$FULL_ACTIVE_FILE" ]; then
  # shellcheck disable=SC1090
  . "$FULL_ACTIVE_FILE"
elif [ -f "$MINIMAL_ACTIVE_FILE" ]; then
  # shellcheck disable=SC1090
  . "$MINIMAL_ACTIVE_FILE"
else
  echo "Error: no active setup file found in $ACTIVE_SETUP_DIR" >&2
  echo "Run s2_init_env_vars.sh first." >&2
  exit 1
fi

mkdir -p "$TARGET_DIR"
cp -a "$SOURCE_DIR/." "$TARGET_DIR/"
echo "Copied docker source tree: $SOURCE_DIR -> $TARGET_DIR"

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

# Clone rkvoice-stream submodule
cd "$TARGET_DIR"/docker_repos/
git clone --recurse-submodule https://github.com/suharvest/rkvoice-stream.git

# Copy rkvoice-stream files to stacks/rkvoice-stream
cp -r rkvoice-stream/baseline -t "$TARGET_DIR"/stacks/rkvoice-stream/
cp -r rkvoice-stream/configs -t "$TARGET_DIR"/stacks/rkvoice-stream/
cp -r rkvoice-stream/docker -t "$TARGET_DIR"/stacks/rkvoice-stream/
cp -r rkvoice-stream/models -t "$TARGET_DIR"/stacks/rkvoice-stream/
cp -r rkvoice-stream/rkvoice_stream -t "$TARGET_DIR"/stacks/rkvoice-stream/
cp rkvoice-stream/pyproject.toml -t "$TARGET_DIR"/stacks/rkvoice-stream/


echo "d1 complete: full docker source copied and rendered in $TARGET_DIR"
