#!/bin/bash

# This script updates a DuckDNS domain with the current public IP address.

set -euo pipefail

# Load configuration
if [ -f "$(dirname "$0")/../config.env" ]; then
    source "$(dirname "$0")/../config.env"
else
    echo "Error: config.env not found."
    exit 1
fi

if [ -z "$DUCKDNS_DOMAIN" ] || [ -z "$DUCKDNS_TOKEN" ]; then
    echo "Error: DUCKDNS_DOMAIN or DUCKDNS_TOKEN is not set in config.env"
    exit 1
fi

LOG_DIR="$(dirname "$0")/../logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/duckdns.log"

echo "Updating DuckDNS domain: $DUCKDNS_DOMAIN" >> "$LOG_FILE"
curl -s "https://www.duckdns.org/update?domains=${DUCKDNS_DOMAIN}&token=${DUCKDNS_TOKEN}&ip=" | tee -a "$LOG_FILE"
echo "" >> "$LOG_FILE"
