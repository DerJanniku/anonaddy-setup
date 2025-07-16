#!/bin/bash

# =============================================
# 🛡️ Automated AnonAddy Installation & Hardening
# =============================================
# Version: 1.0
# Author: Cline
# =============================================

set -euo pipefail
IFS=$'\n\t'

# --- Configuration ---
CONFIG_FILE="config.env"
LOG_FILE="logs/install.log"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# --- Functions ---
log() {
    echo -e "${GREEN}[INFO] $1${NC}" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}" | tee -a "$LOG_FILE"
    exit 1
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        error "Please run this script as root or with sudo."
    fi
}

check_bool() {
    [[ "$1" == "true" ]] || return 1
}

# --- Main Logic ---
main() {
    check_root

    if [ ! -f "$CONFIG_FILE" ]; then
        error "Configuration file $CONFIG_FILE not found! Please copy config.env.example to config.env and fill it out."
    fi

    source "$CONFIG_FILE"
    mkdir -p logs backups

    log "Starting AnonAddy Hardened Setup..."

    # --- System Setup ---
    log "Updating system..."
    apt-get update && apt-get upgrade -y

    log "Installing base packages..."
    apt-get install -y curl git ufw fail2ban cron docker.io docker-compose unzip

    # --- Security ---
    if check_bool "$ENABLE_UFW"; then
        log "Setting up UFW firewall..."
        ufw allow ssh
        ufw allow http
        ufw allow https
        ufw --force enable
    fi

    if check_bool "$ENABLE_FAIL2BAN"; then
        log "Enabling Fail2Ban..."
        systemctl enable fail2ban
        systemctl start fail2ban
    fi

    if check_bool "$ENABLE_TOR_HARDEN"; then
        log "Applying TOR hardening..."
        bash scripts/tor_harden.sh
    fi

    if check_bool "$ENABLE_IP_BLACKLIST"; then
        log "Setting up IP blacklist..."
        bash scripts/ip_blacklist_update.sh
        cp cronjobs/ipblacklist.cron /etc/cron.d/ipblacklist
        chmod 644 /etc/cron.d/ipblacklist
    fi

    # --- DNS ---
    if check_bool "$USE_DUCKDNS"; then
        log "Setting up DuckDNS..."
        bash scripts/update_duckdns.sh
        cp cronjobs/duckdns.cron /etc/cron.d/duckdns
        chmod 644 /etc/cron.d/duckdns
    fi

    if check_bool "$USE_CLOUDFLARE"; then
        log "Setting up Cloudflare DNS..."
        bash scripts/cloudflare_update.sh
        cp cronjobs/cloudflare.cron /etc/cron.d/cloudflare
        chmod 644 /etc/cron.d/cloudflare
    fi

    # --- Docker Services ---
    if check_bool "$ENABLE_TRAEFIK"; then
        log "Deploying Traefik..."
        mkdir -p traefik
        touch traefik/acme.json
        chmod 600 traefik/acme.json
        docker-compose -f traefik/docker-compose.yml up -d
    fi

    if check_bool "$ENABLE_ANONADDY"; then
        log "Deploying AnonAddy..."
        if [ ! -d "anonaddy/docker" ]; then
            git clone https://github.com/anonaddy/docker.git anonaddy/docker
        fi
        cd anonaddy/docker
        cp .env.example .env
        sed -i "s/APP_DOMAIN=.*/APP_DOMAIN=$DOMAIN/" .env
        sed -i "s/ADMIN_EMAIL=.*/ADMIN_EMAIL=$EMAIL/" .env
        docker-compose up -d
        cd ../..
    fi

    if check_bool "$ENABLE_WATCHTOWER"; then
        log "Deploying Watchtower..."
        docker run -d \
            --name watchtower \
            -v /var/run/docker.sock:/var/run/docker.sock \
            containrrr/watchtower --cleanup --interval 86400
    fi

    # --- Backups ---
    if check_bool "$ENABLE_BACKUP"; then
        log "Setting up backups..."
        mkdir -p "$BACKUP_DIR"
        cp cronjobs/backup.cron /etc/cron.d/anonaddy-backup
        chmod 644 /etc/cron.d/anonaddy-backup
    fi

    # --- Monitoring ---
    if check_bool "$ENABLE_MONITORING"; then
        log "Setting up monitoring..."
        if [ ! -z "${UPTIMEROBOT_PING_URL:-}" ]; then
            (crontab -l 2>/dev/null; echo "*/5 * * * * curl -fsS --retry 3 ${UPTIMEROBOT_PING_URL}") | crontab -
        fi
    fi

    log "Installation complete!"
    log "AnonAddy should be available at https://$DOMAIN"
    if check_bool "$ENABLE_TRAEFIK"; then
        log "Traefik dashboard should be available at https://traefik.$DOMAIN"
    fi
}

main
