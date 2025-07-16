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

# --- Source Functions ---
source "scripts/functions.sh"

# --- Functions ---
check_root() {
    if [ "$EUID" -ne 0 ]; then
        error "Please run this script as root or with sudo."
    fi
}

setup_system() {
    log "Updating system..."
    apt-get update && apt-get upgrade -y
    log "Installing base packages..."
    apt-get install -y curl git ufw fail2ban cron docker.io docker-compose unzip aide auditd lynis
}

harden_ssh() {
    if check_bool "$SETUP_SECURE_SSH"; then
        log "Applying SSH hardening..."
        useradd -m -s /bin/bash "$ADMIN_USER"
        usermod -aG sudo "$ADMIN_USER"
        sed -i "s/^#Port 22/Port $SSH_PORT/" /etc/ssh/sshd_config
        sed -i "s/^PermitRootLogin.*/PermitRootLogin no/" /etc/ssh/sshd_config
        sed -i "s/^#PasswordAuthentication yes/PasswordAuthentication no/" /etc/ssh/sshd_config
        echo "AllowUsers $ADMIN_USER" >> /etc/ssh/sshd_config
        systemctl restart sshd
    fi
}

setup_ufw() {
    if check_bool "$ENABLE_UFW"; then
        log "Setting up UFW firewall..."
        ufw default deny incoming
        ufw default allow outgoing
        if [ -n "$SSH_ALLOWED_IP" ]; then
            ufw allow from "$SSH_ALLOWED_IP" to any port "$SSH_PORT"
        else
            ufw allow "$SSH_PORT"
        fi
        ufw allow http
        ufw allow https
        ufw --force enable
    fi
}

setup_fail2ban() {
    if check_bool "$ENABLE_FAIL2BAN"; then
        log "Enabling Fail2Ban..."
        cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
        sed -i "s/bantime  = 10m/bantime  = 1h/" /etc/fail2ban/jail.local
        sed -i "s/maxretry = 5/maxretry = 3/" /etc/fail2ban/jail.local
        cat >> /etc/fail2ban/jail.local <<EOF

[nginx-http-auth]
enabled = true
port    = http,https
logpath = /var/log/nginx/access.log

[nginx-badbots]
enabled = true
port    = http,https
logpath = /var/log/nginx/access.log
maxretry = 2
EOF
        systemctl enable fail2ban
        systemctl start fail2ban
    fi
}

harden_tor() {
    if check_bool "$ENABLE_TOR_HARDEN"; then
        log "Applying TOR hardening..."
        bash scripts/tor_harden.sh
    fi
}

setup_ip_blacklist() {
    if check_bool "$ENABLE_IP_BLACKLIST"; then
        log "Setting up IP blacklist..."
        bash scripts/ip_blacklist_update.sh
        cp cronjobs/ipblacklist.cron /etc/cron.d/ipblacklist
        chmod 644 /etc/cron.d/ipblacklist
    fi
}

setup_aide() {
    if check_bool "$ENABLE_AIDE"; then
        log "Initializing AIDE..."
        aideinit
        cp /var/lib/aide/aide.db.new /var/lib/aide/aide.db
    fi
}

setup_auditd() {
    if check_bool "$ENABLE_AUDITD"; then
        log "Configuring auditd..."
        systemctl enable auditd
        systemctl start auditd
    fi
}

run_lynis() {
    if check_bool "$ENABLE_LYNIS"; then
        log "Running Lynis security scan..."
        lynis audit system --quiet --log-file /var/log/lynis-report.dat
    fi
}

setup_dns() {
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
}

deploy_npm() {
    if check_bool "$ENABLE_NPM"; then
        log "Deploying Nginx Proxy Manager..."
        mkdir -p npm
        docker-compose -f npm/docker-compose.yml up -d
    fi
}

deploy_anonaddy() {
    if check_bool "$ENABLE_ANONADDY"; then
        log "Deploying AnonAddy..."
        if [ ! -d "anonaddy/docker" ]; then
            git clone https://github.com/anonaddy/docker.git anonaddy/docker
        fi
        pushd anonaddy/docker
        cp .env.example .env
        sed -i "s/APP_DOMAIN=.*/APP_DOMAIN=$DOMAIN/" .env
        sed -i "s/ADMIN_EMAIL=.*/ADMIN_EMAIL=$EMAIL/" .env
        docker-compose up -d
        popd
    fi
}

deploy_watchtower() {
    if check_bool "$ENABLE_WATCHTOWER"; then
        log "Deploying Watchtower..."
        docker run -d \
            --name watchtower \
            -v /var/run/docker.sock:/var/run/docker.sock \
            containrrr/watchtower --cleanup --interval 86400
    fi
}

setup_backups() {
    if check_bool "$ENABLE_BACKUP"; then
        log "Setting up backups..."
        mkdir -p "$BACKUP_DIR"
        cp cronjobs/backup.cron /etc/cron.d/anonaddy-backup
        chmod 644 /etc/cron.d/anonaddy-backup
    fi
}

setup_monitoring() {
    if check_bool "$ENABLE_MONITORING"; then
        log "Setting up monitoring..."
        if [ ! -z "${UPTIMEROBOT_PING_URL:-}" ]; then
            echo "*/5 * * * * root curl -fsS --retry 3 ${UPTIMEROBOT_PING_URL}" > /etc/cron.d/uptimerobot
            chmod 644 /etc/cron.d/uptimerobot
        fi
    fi
}

# --- Main Logic ---
main() {
    check_root

    if [ ! -f "$CONFIG_FILE" ]; then
        error "Configuration file $CONFIG_FILE not found! Please copy config.env.example to config.env and fill it out."
    fi

    source "$CONFIG_FILE"
    mkdir -p logs backups

    validate_config

    log "Starting AnonAddy Hardened Setup..."

    setup_system
    harden_ssh
    setup_ufw
    setup_fail2ban
    harden_tor
    setup_ip_blacklist
    setup_aide
    setup_auditd
    run_lynis
    setup_dns
    deploy_npm
    deploy_anonaddy
    deploy_watchtower
    setup_backups
    setup_monitoring

    log "Installation complete!"
    log "AnonAddy should be available at https://$DOMAIN"
    if check_bool "$ENABLE_NPM"; then
        log "Nginx Proxy Manager should be available at http://<your-server-ip>:81"
        log "Default login: admin@example.com / changeme"
    fi
}

main
