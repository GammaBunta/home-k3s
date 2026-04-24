#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <app>" >&2
  echo "Exemple: $0 longhorn" >&2
  exit 1
fi

APP="$1"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/flux/apps/$APP"
KUBECONFIG_FILE="$HOME/.kube/home-k3s.yaml"
INVENTORY_FILE="$ROOT_DIR/ansible/inventory.ini"

if [[ ! -d "$APP_DIR" ]]; then
  echo "Application Flux inconnue: $APP" >&2
  echo "Disponibles:" >&2
  ls -1 "$ROOT_DIR/flux/apps" >&2
  exit 1
fi

if [[ -f "$KUBECONFIG_FILE" ]]; then
  export KUBECONFIG="$KUBECONFIG_FILE"
fi

if [[ "$APP" == "adguard" ]]; then
  MASTER_IP="$(awk '
    /^\[master\]/{in_master=1; next}
    /^\[/{in_master=0}
    in_master && NF {print $1; exit}
  ' "$INVENTORY_FILE")"

  if [[ -z "$MASTER_IP" ]]; then
    echo "Impossible de lire l'IP master dans $INVENTORY_FILE" >&2
    exit 1
  fi

  ADGUARD_USER="${ADGUARD_USER:-samuel}"
  ADGUARD_PASS="${ADGUARD_PASS:-}"

  if [[ -z "$ADGUARD_PASS" ]]; then
    if command -v openssl >/dev/null 2>&1; then
      ADGUARD_PASS="$(openssl rand -base64 18 | tr -d '=+/')"
    else
      ADGUARD_PASS="$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 24)"
    fi
    echo "[flux] ADGUARD_PASS non fourni: mot de passe genere automatiquement." >&2
  fi

  kubectl -n adguard create secret generic adguard-admin \
    --from-literal=username="$ADGUARD_USER" \
    --from-literal=password="$ADGUARD_PASS" \
    --dry-run=client -o yaml | kubectl apply -f -

  kubectl -n adguard create configmap adguard-settings \
    --from-literal=masterIp="$MASTER_IP" \
    --dry-run=client -o yaml | kubectl apply -f -

  echo "[flux] Secret adguard-admin et configmap adguard-settings appliques (masterIp=$MASTER_IP)."
fi

echo "[flux] Deploiement de l'application: $APP"
kubectl apply -f "$ROOT_DIR/flux/sources/helmrepositories.yaml"
kubectl apply -k "$APP_DIR"

echo "[flux] Application $APP deployee."