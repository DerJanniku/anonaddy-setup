#!/bin/bash

# =============================================
# 🛡️ Helper Functions for AnonAddy Setup
# =============================================

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[INFO] $1${NC}" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}" | tee -a "$LOG_FILE"
    exit 1
}

check_bool() {
    [[ "$1" == "true" ]] || return 1
}

validate_config() {
    log "Validating configuration..."
    local missing_vars=()
    local required_vars=(
        "DOMAIN" "EMAIL" "ADMIN_USER" "SSH_PORT" "BACKUP_DIR"
    )

    if check_bool "$USE_DUCKDNS"; then
        required_vars+=("DUCKDNS_DOMAIN" "DUCKDNS_TOKEN")
    fi

    if check_bool "$USE_CLOUDFLARE"; then
        required_vars+=("CF_API_TOKEN" "CF_ZONE_ID" "CF_RECORD_NAME")
    fi

    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            missing_vars+=("$var")
        fi
    done

    if [ ${#missing_vars[@]} -ne 0 ]; then
        error "The following required variables are not set in config.env: ${missing_vars[*]}"
    fi
}
