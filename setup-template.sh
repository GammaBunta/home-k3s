#!/bin/bash

# --- CONFIGURATION ---
TEMPLATE_VM_ID="${1:-9000}"
TEMPLATE_NAME="ubuntu-2404-template"
UBUNTU_IMG_URL="https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
DISK_SIZE="32G"
STORAGE="local-lvm"

echo "🚀 Création du template Ubuntu 24.04 cloud-init (VM $TEMPLATE_VM_ID)..."

# ============================================
# 1. Suppression du template existant
# ============================================
if qm status "$TEMPLATE_VM_ID" &>/dev/null; then
  echo "⚠️ La VM $TEMPLATE_VM_ID existe déjà, suppression..."
  qm destroy "$TEMPLATE_VM_ID" --purge
fi

# ============================================
# 2. Téléchargement de l'image cloud
# ============================================
echo "📥 Téléchargement de l'image Ubuntu 24.04..."
wget -q --show-progress "$UBUNTU_IMG_URL" -O /tmp/ubuntu-cloud.img

# ============================================
# 3. Injection de qemu-guest-agent
# ============================================
echo "📦 Installation de libguestfs-tools..."
apt install -y libguestfs-tools 2>/dev/null

echo "💉 Injection de qemu-guest-agent dans l'image..."
virt-customize -a /tmp/ubuntu-cloud.img --install qemu-guest-agent

# ============================================
# 4. Création et configuration de la VM
# ============================================
echo "🖥️  Création de la VM..."
qm create "$TEMPLATE_VM_ID" --name "$TEMPLATE_NAME" --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0

echo "💾 Import du disque..."
qm importdisk "$TEMPLATE_VM_ID" /tmp/ubuntu-cloud.img "$STORAGE"

echo "⚙️  Configuration de la VM..."
qm set "$TEMPLATE_VM_ID" --scsihw virtio-scsi-pci --scsi0 "$STORAGE:vm-${TEMPLATE_VM_ID}-disk-0"
qm set "$TEMPLATE_VM_ID" --ide2 "$STORAGE:cloudinit"
qm set "$TEMPLATE_VM_ID" --boot c --bootdisk scsi0
qm set "$TEMPLATE_VM_ID" --serial0 socket --vga serial0
qm set "$TEMPLATE_VM_ID" --agent enabled=1

echo "📏 Redimensionnement du disque à $DISK_SIZE..."
qm resize "$TEMPLATE_VM_ID" scsi0 "$DISK_SIZE"

# ============================================
# 5. Conversion en template
# ============================================
echo "📋 Conversion en template..."
qm template "$TEMPLATE_VM_ID"

rm -f /tmp/ubuntu-cloud.img

echo "---------------------------------------------------"
echo "✅ Template créé !"
echo "  VM ID : $TEMPLATE_VM_ID"
echo "  Nom   : $TEMPLATE_NAME"
echo "  Disque: $DISK_SIZE"
echo ""
echo "Mets cette valeur dans terraform.tfvars :"
echo "  template_vm_id = $TEMPLATE_VM_ID"
echo "---------------------------------------------------"
