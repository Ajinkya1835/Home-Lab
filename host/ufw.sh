#!/usr/bin/env bash
# Default-deny firewall: services are reachable only through the tailscale0 interface.
set -euo pipefail
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 41641/udp comment 'tailscale direct connections'
for p in 22 445 2283 9000 19999; do
  sudo ufw allow in on tailscale0 to any port "$p" proto tcp
done
sudo ufw --force enable
sudo ufw status verbose
