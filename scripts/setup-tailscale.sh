#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INVENTORY_FILE="$ROOT_DIR/ansible/inventory.ini"
KUBECONFIG_FILE="$HOME/.kube/home-k3s.yaml"
TS_AUTHKEY="${TS_AUTHKEY:-}"

if [[ -z "$TS_AUTHKEY" ]]; then
  echo "TS_AUTHKEY est requis. Exemple:" >&2
  echo "  export TS_AUTHKEY=tskey-xxxxxxxx" >&2
  echo "  make tailscale" >&2
  exit 1
fi

MASTER_HOST="$(awk '
  /^\[master\]/{in_master=1; next}
  /^\[/{in_master=0}
  in_master && NF {print $1; exit}
' "$INVENTORY_FILE")"

if [[ -z "$MASTER_HOST" ]]; then
  echo "Impossible de lire l'hote master dans $INVENTORY_FILE" >&2
  exit 1
fi

ssh "ubuntu@$MASTER_HOST" "curl -fsSL https://tailscale.com/install.sh | sh"
ssh "ubuntu@$MASTER_HOST" "sudo tailscale up --authkey '$TS_AUTHKEY' --ssh --accept-routes --accept-dns=false"

TAILSCALE_IP="$(ssh "ubuntu@$MASTER_HOST" "sudo tailscale ip -4 | head -n1")"

if [[ -z "$TAILSCALE_IP" ]]; then
  echo "Impossible de recuperer l'IP Tailscale du master." >&2
  exit 1
fi

if [[ -f "$KUBECONFIG_FILE" ]]; then
  sed -i.bak "s#server: https://.*:6443#server: https://$TAILSCALE_IP:6443#g" "$KUBECONFIG_FILE"
  rm -f "$KUBECONFIG_FILE.bak"
fi

echo "k3s est accessible via Tailscale sur $TAILSCALE_IP:6443"