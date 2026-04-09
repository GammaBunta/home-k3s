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

echo "🚀 Début de la configuration des accès pour Terraform..."

# 1. Création d'un rôle personnalisé robuste
# On regroupe les droits VM, Datastore et Network
echo "📦 Création du rôle $ROLE_NAME..."
pveum role add $ROLE_NAME -privs "VM.Allocate VM.Clone VM.Config.CDROM VM.Config.CPU VM.Config.Cloudinit VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Monitor VM.Audit VM.PowerMgmt Datastore.AllocateSpace Datastore.Audit Datastore.Allocate SDN.Use Sys.Audit" 2>/dev/null || echo "⚠️ Le rôle existe déjà."

# 2. Création de l'utilisateur (on demande le mot de passe s'il n'existe pas)
echo "👤 Création de l'utilisateur $USER_NAME@$REALM..."
pveum user add "$USER_NAME@$REALM" --password "$USER_PASSWORD" 2>/dev/null || echo "⚠️ L'utilisateur existe déjà."

# 3. Application des permissions (ACL) sur la racine (/)
echo "🔐 Application des ACLs..."
pveum acl modify / -user "$USER_NAME@$REALM" -role "$ROLE_NAME"

# 4. Génération du Token API
echo "🔑 Génération du Token API..."
# On utilise --privsep 0 pour que le token ait les mêmes droits que l'utilisateur
TOKEN_INFO=$(pveum user token add "$USER_NAME@$REALM" "$TOKEN_NAME" --privsep 0 --output-format json)

echo "---------------------------------------------------"
echo "✅ Configuration terminée !"
echo "Conserve bien ces informations pour ton fichier provider.tf :"
echo ""
echo "Token ID : $USER_NAME@$REALM!$TOKEN_NAME"
echo "Secret : (Regarde la ligne 'value' ci-dessous)"
echo ""
echo "$TOKEN_INFO" | grep -o '"value": "[^"]*"' | sed 's/"value": "//;s/"//'
echo "---------------------------------------------------"