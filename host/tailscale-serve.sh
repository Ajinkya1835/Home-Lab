#!/usr/bin/env bash
# Expose every service on the tailnet only; publish ONLY the static portfolio to the internet.
# Replace nothing here with real hostnames - Tailscale fills them in.
set -euo pipefail

serve() { sudo tailscale serve --bg --https="$1" "http://127.0.0.1:$2"; }

serve 8443 8081    # Vaultwarden   (tailnet only - never Funnel a password manager)
serve 8444 2283    # Immich
serve 8445 5678    # n8n
serve 8450 3030    # Homepage
serve 8451 8092    # File Browser
serve 8454 8888    # Dozzle
serve 8461 19999   # Netdata
serve 8463 8085    # Scrutiny
serve 10000 8096   # Jellyfin      (tailnet only)

# The one public endpoint: static portfolio served by the `edge` container.
sudo tailscale funnel --bg --https=443 http://127.0.0.1:8480
tailscale serve status
