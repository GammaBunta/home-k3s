#!/bin/bash

# --- CONFIGURATION ---
USER_NAME="terraform-user"
REALM="pve"
TOKEN_NAME="terraform-token"
ROLE_NAME="TerraformFull"

# Récupération du mot de passe via paramètre ou saisie interactive
if [ -n "$1" ]; then
  USER_PASSWORD="$1"
else
  read -s -p "🔒 Entrez le mot de passe pour $USER_NAME@$REALM : " USER_PASSWORD
  echo
fi

echo "🚀 Début de la configuration auth..."

# ============================================
# 1. Rôle personnalisé avec les bons privilèges
# ============================================
echo "📦 Création du rôle $ROLE_NAME..."
pveum role add "$ROLE_NAME" -privs "VM.Allocate VM.Clone VM.Config.CDROM VM.Config.CPU VM.Config.Cloudinit VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Console VM.Audit VM.PowerMgmt Datastore.AllocateSpace Datastore.Audit Datastore.Allocate SDN.Use Sys.Audit Sys.Modify" 2>/dev/null \
  || pveum role modify "$ROLE_NAME" -privs "VM.Allocate VM.Clone VM.Config.CDROM VM.Config.CPU VM.Config.Cloudinit VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Console VM.Audit VM.PowerMgmt Datastore.AllocateSpace Datastore.Audit Datastore.Allocate SDN.Use Sys.Audit Sys.Modify"

# ============================================
# 2. Création de l'utilisateur
# ============================================
echo "👤 Création de l'utilisateur $USER_NAME@$REALM..."
pveum user add "$USER_NAME@$REALM" --password "$USER_PASSWORD" 2>/dev/null || echo "⚠️ L'utilisateur existe déjà."

# ============================================
# 3. Application des ACLs
# ============================================
echo "🔐 Application des ACLs..."
pveum acl modify / -user "$USER_NAME@$REALM" -role "$ROLE_NAME"

# ============================================
# 4. Génération du Token API (privsep=0)
# ============================================
echo "🔑 Génération du Token API (privsep désactivé)..."
pveum user token remove "$USER_NAME@$REALM" "$TOKEN_NAME" 2>/dev/null
TOKEN_INFO=$(pveum user token add "$USER_NAME@$REALM" "$TOKEN_NAME" --privsep 0 --output-format json)
TOKEN_SECRET=$(echo "$TOKEN_INFO" | grep -o '"value": "[^"]*"' | sed 's/"value": "//;s/"//')

# ============================================
# Résumé
# ============================================
echo "---------------------------------------------------"
echo "✅ Auth configurée !"
echo ""
echo "Token ID     : $USER_NAME@$REALM!$TOKEN_NAME"
echo "Token Secret : $TOKEN_SECRET"
echo ""
echo "Mets ces valeurs dans terraform.tfvars :"
echo "  proxmox_api_token_id     = \"$USER_NAME@$REALM!$TOKEN_NAME\""
echo "  proxmox_api_token_secret = \"$TOKEN_SECRET\""
echo "---------------------------------------------------"
