#!/bin/sh
set -eu

case "${0##*/}" in
  sh|dash|bash)
    echo "Error: do not source this script. Run it with 'sh s2_helper_script.sh' or './s2_helper_script.sh'." >&2
    return 1 2>/dev/null || exit 1
    ;;
esac

SCRIPT_DIR="/srv/horto-os/scripts"
REPO_ROOT="/srv/horto-os"
TEMPLATE_FILE="$REPO_ROOT/config/os-configuration.env"
ACTIVE_SETUP_DIR="/srv/active_setup"
ACTIVE_FILE="$ACTIVE_SETUP_DIR/os-configuration.env"

if [ ! -f "$TEMPLATE_FILE" ]; then
  echo "Error: template file not found: $TEMPLATE_FILE" >&2
  exit 1
fi

mkdir -p "$ACTIVE_SETUP_DIR"

if [ ! -f "$ACTIVE_FILE" ]; then
  cp "$TEMPLATE_FILE" "$ACTIVE_FILE"
  echo "Created active variables file: $ACTIVE_FILE"
fi

# shellcheck disable=SC1090
. "$ACTIVE_FILE"

prompt_value() {
  current_value="$1"
  prompt_label="$2"

  printf "%s [%s]: " "$prompt_label" "$current_value" >&2
  IFS= read -r input || true

  if [ -n "$input" ]; then
    printf '%s' "$input"
  else
    printf '%s' "$current_value"
  fi
}

escape_double_quotes() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

OS_TYPE=$(prompt_value "${OS_TYPE:-debian}" "debian/armbian select")
NPU_TYPE=$(prompt_value "${NPU_TYPE:-rk3588}" "NPU or GPU type ")
INSTALL_TYPE=$(prompt_value "${INSTALL_TYPE:-home}" "home/sat/hortex select")
IOT_LAN=$(prompt_value "${IOT_LAN:-y}" "# y/n: if Yes the setup will create an independend IOT_LAN")
MY_HOSTNAME=$(prompt_value "${MY_HOSTNAME:-Horto-OS_xxx}" "Device hostname")
MY_URL=$(prompt_value "${MY_URL:-YourDomainName.net}" "Public URL / domain")

cat > "$ACTIVE_FILE" <<EOF
OS_TYPE="$(escape_double_quotes "$OS_TYPE")"
NPU_TYPE="$(escape_double_quotes "$NPU_TYPE")"
INSTALL_TYPE="$(escape_double_quotes "$INSTALL_TYPE")"
IOT_LAN="$(escape_double_quotes "$IOT_LAN")"
MY_HOSTNAME="$(escape_double_quotes "$MY_HOSTNAME")"
MY_URL="$(escape_double_quotes "$MY_URL")"
EOF

echo "Saved active variables to $ACTIVE_FILE"
