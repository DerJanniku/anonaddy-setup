#!/bin/bash

# This script applies TOR hardening settings to the system.

set -euo pipefail

log() {
    echo "[INFO] $1"
}

error() {
    echo "[ERROR] $1"
    exit 1
}

log "Applying TOR hardening settings..."

# Disable ICMP redirects
sysctl -w net.ipv4.conf.all.accept_redirects=0
sysctl -w net.ipv4.conf.default.accept_redirects=0
sysctl -w net.ipv6.conf.all.accept_redirects=0
sysctl -w net.ipv6.conf.default.accept_redirects=0

# Enable TCP SYN cookies
sysctl -w net.ipv4.tcp_syncookies=1

# Enable IP spoofing protection
sysctl -w net.ipv4.conf.all.rp_filter=1
sysctl -w net.ipv4.conf.default.rp_filter=1

# Ignore ICMP broadcasts
sysctl -w net.ipv4.icmp_echo_ignore_broadcasts=1

# Log martian packets
sysctl -w net.ipv4.conf.all.log_martians=1

# Make the changes persistent
cat > /etc/sysctl.d/99-tor-harden.conf <<EOF
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.conf.all.log_martians = 1
EOF

sysctl -p /etc/sysctl.d/99-tor-harden.conf

log "TOR hardening applied."
