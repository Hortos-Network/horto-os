#!/bin/sh
set -eu

# Script to export dnsmasq leases to files for Homepage
LEASE_FILE="/var/lib/misc/dnsmasq.leases"
OUTPUT_DIR="/srv/docker/assets"
OUTPUT_HTML="$OUTPUT_DIR/leases.html"

# Skip if lease file has not changed since last export
if [ -f "$LEASE_FILE" ] && [ -f "$OUTPUT_HTML" ]; then
  if [ "$LEASE_FILE" -ot "$OUTPUT_HTML" ]; then
    echo "Leases unchanged since last export; skipping."
    exit 0
  fi
fi

if [ ! -f "$LEASE_FILE" ]; then
  echo "[]" > "$OUTPUT_DIR/leases.json"
  echo "<html><body><p>No DHCP leases found.</p></body></html>" > "$OUTPUT_HTML"
  echo "Lease file not found, wrote empty output."
  exit 0
fi

# JSON output (for future use)
{
  printf "[\n"
  first=true
  while read -r expiry mac ip hostname client_id; do
    if [ "$first" = true ]; then
      first=false
    else
      printf ",\n"
    fi
    printf '  { "hostname": "%s", "ip": "%s", "mac": "%s", "expires": "%s" }' "$hostname" "$ip" "$mac" "$expiry"
  done < "$LEASE_FILE"
  printf "\n]\n"
} > "$OUTPUT_DIR/leases.json"

# HTML table output for Homepage iframe
{
  printf '<!DOCTYPE html>\n<html lang="en">\n<head>\n<meta charset="utf-8">\n<meta name="viewport" content="width=device-width, initial-scale=1">\n<style>\n'
  printf 'body{font-family:ui-sans-serif,sans-serif;margin:0;padding:0;background:transparent;color:inherit}\n'
  printf 'table{width:100%%;border-collapse:collapse;font-size:.85rem}\n'
  printf 'th,td{text-align:left;padding:6px 8px;border-bottom:1px solid rgba(255,255,255,.12)}\n'
  printf 'th{font-weight:600;opacity:.7;text-transform:uppercase;font-size:.7rem;letter-spacing:.5px}\n'
  printf 'tr:hover{background:rgba(255,255,255,.05)}\n'
  printf '</style>\n</head>\n<body>\n'
  printf '<table>\n<tr><th>Hostname</th><th>IP</th><th>MAC</th></tr>\n'
  while read -r expiry mac ip hostname client_id; do
    printf '<tr><td>%s</td><td>%s</td><td style="font-family:monospace;font-size:.8rem">%s</td></tr>\n' "$hostname" "$ip" "$mac"
  done < "$LEASE_FILE"
  printf '</table>\n</body>\n</html>\n'
} > "$OUTPUT_HTML"

echo "DHCP leases exported to $OUTPUT_DIR/leases.json and $OUTPUT_HTML"