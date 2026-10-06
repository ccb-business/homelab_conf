#!/bin/bash
# Connects this machine to the homelab network.
# Safe to run more than once.
set -euo pipefail

LOGIN_SERVER="https://vpn.home.eluusive.com"

echo "== Homelab network setup =="

if ! command -v tailscale &> /dev/null; then
  echo "Tailscale not found, installing..."
  if [[ "$OSTYPE" == "darwin"* ]]; then
    if command -v brew &> /dev/null; then
      brew install tailscale
      sudo brew services start tailscale
    else
      echo "Homebrew not found. Install Tailscale manually from:"
      echo "  https://tailscale.com/download/mac"
      exit 1
    fi
  else
    curl -fsSL https://tailscale.com/install.sh | sh
  fi
else
  echo "Tailscale already installed."
fi
echo "Flushing existing connections..."
sudo tailscale down
sudo tailscale logout
echo "Connecting and opening browser login..."
sudo tailscale up \
  --login-server="$LOGIN_SERVER" \
  --accept-routes \
  --reset

echo ""
echo "Done. If a browser window opened, log in with the username and"
echo "temporary password you were given, then set your own password."
echo ""
echo "Checking connection status:"
tailscale status
