#!/bin/bash

# This script updates a Cloudflare DNS record with the current public IP address.

set -euo pipefail

# Load configuration
if [ -f "$(dirname "$0")/../config.env" ]; then
    source "$(dirname "$0")/../config.env"
else
    echo "Error: config.env not found."
    exit 1
fi

if [ -z "$CF_API_TOKEN" ] || [ -z "$CF_ZONE_ID" ] || [ -z "$CF_RECORD_NAME" ]; then
    echo "Error: Cloudflare variables are not set in config.env"
    exit 1
fi

LOG_DIR="$(dirname "$0")/../logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/cloudflare.log"

IP=$(curl -s http://ipv4.icanhazip.com/)

echo "Updating Cloudflare record for $CF_RECORD_NAME to $IP" >> "$LOG_FILE"

curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records/${CF_RECORD_NAME}" \
     -H "Authorization: Bearer ${CF_API_TOKEN}" \
     -H "Content-Type: application/json" \
     --data "{\"type\":\"A\",\"name\":\"${CF_RECORD_NAME}\",\"content\":\"${IP}\",\"ttl\":120,\"proxied\":false}" | tee -a "$LOG_FILE"

echo "" >> "$LOG_FILE"
