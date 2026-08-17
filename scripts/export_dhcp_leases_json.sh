#!/bin/sh
set -eu

# Script to export dnsmasq leases to a JSON file for Homepage
LEASE_FILE="/var/lib/misc/dnsmasq.leases"
OUTPUT_FILE="/srv/docker/app_data/homepage/config/leases.json"

if [ ! -f "$LEASE_FILE" ]; then
  echo "[]" > "$OUTPUT_FILE"
  echo "Lease file not found, wrote empty JSON."
  exit 0
fi

# Format: <expiry> <mac> <ip> <hostname> <client-id>
# We convert this to JSON format
echo "[" > "$OUTPUT_FILE"
first=true
while read -r expiry mac ip hostname client_id; do
  if [ "$first" = true ]; then
    first=false
  else
    echo "," >> "$OUTPUT_FILE"
  fi
  cat <<EOF >> "$OUTPUT_FILE"
  {
    "hostname": "$hostname",
    "ip": "$ip",
    "mac": "$mac"
  }
EOF
done < "$LEASE_FILE"
echo "]" >> "$OUTPUT_FILE"

echo "DHCP leases exported to $OUTPUT_FILE"
