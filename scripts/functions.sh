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
