#!/bin/bash

# This script downloads a list of malicious IPs and blocks them with UFW.

set -euo pipefail

log() {
    echo "[INFO] $1"
}

error() {
    echo "[ERROR] $1"
    exit 1
}

log "Updating IP blacklist..."

BLACKLIST_URL="https://lists.blocklist.de/lists/all.txt"
BLACKLIST_FILE="/tmp/blacklist.txt"

# Download the blacklist
curl -s "$BLACKLIST_URL" -o "$BLACKLIST_FILE"

if [ ! -f "$BLACKLIST_FILE" ]; then
    error "Failed to download blacklist."
fi

# Add each IP to UFW
while IFS= read -r ip; do
    ufw insert 1 deny from "$ip" to any comment "IP Blacklist"
done < "$BLACKLIST_FILE"

# Clean up
rm "$BLACKLIST_FILE"

log "IP blacklist updated."
