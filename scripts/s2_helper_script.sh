#!/bin/sh
set -eu

case "${0##*/}" in
  sh|dash|bash)
    echo "Error: do not source this script. Run it with 'sh s2_helper_script.sh' or './s2_helper_script.sh'." >&2
    return 1 2>/dev/null || exit 1
    ;;
esac

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
TEMPLATE_FILE="$REPO_ROOT/config/my_variables.env"
ACTIVE_SETUP_DIR="/srv/active_setup"
ACTIVE_FILE="$ACTIVE_SETUP_DIR/my_variables.env"

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

MY_HOSTNAME=$(prompt_value "${MY_HOSTNAME:-Horto-OS_xxx}" "Device hostname")
WIFI_INTERFACE=$(prompt_value "${WIFI_INTERFACE:-wlx0_xxxxx}" "WiFi interface")
WIFI_SSID=$(prompt_value "${WIFI_SSID:-Horto-IoT-LAN}" "WiFi SSID")
WIFI_PASSPHRASE=$(prompt_value "${WIFI_PASSPHRASE:-}" "WiFi passphrase")
MY_URL=$(prompt_value "${MY_URL:-YourDomainName.net}" "Public URL / domain")

cat > "$ACTIVE_FILE" <<EOF
MY_HOSTNAME="$(escape_double_quotes "$MY_HOSTNAME")"
WIFI_INTERFACE="$(escape_double_quotes "$WIFI_INTERFACE")"
WIFI_SSID="$(escape_double_quotes "$WIFI_SSID")"
WIFI_PASSPHRASE="$(escape_double_quotes "$WIFI_PASSPHRASE")"
MY_URL="$(escape_double_quotes "$MY_URL")"
EOF

echo "Saved active variables to $ACTIVE_FILE"
