#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INVENTORY_FILE="$ROOT_DIR/ansible/inventory.ini"
KUBECONFIG_DIR="$HOME/.kube"
KUBECONFIG_FILE="$KUBECONFIG_DIR/home-k3s.yaml"

if ! command -v flux >/dev/null 2>&1; then
  echo "[flux] CLI non trouvee. Installation en cours..."
  curl -s https://fluxcd.io/install.sh | sudo bash
fi

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl est requis mais non installe." >&2
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

mkdir -p "$KUBECONFIG_DIR"
ssh "ubuntu@$MASTER_HOST" "sudo cat /etc/rancher/k3s/k3s.yaml" \
  | sed "s/127.0.0.1/$MASTER_HOST/g" > "$KUBECONFIG_FILE"
chmod 600 "$KUBECONFIG_FILE"
export KUBECONFIG="$KUBECONFIG_FILE"

if ! kubectl get namespace flux-system >/dev/null 2>&1; then
  echo "[flux] Installation des controllers FluxCD..."
  flux install
else
  echo "[flux] flux-system existe deja, installation ignoree."
fi

echo "[flux] Application des HelmRepository..."
kubectl apply -f "$ROOT_DIR/flux/sources/helmrepositories.yaml"

echo "[flux] Bootstrap termine."