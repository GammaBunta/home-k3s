# 1. Master K3s
module "k3s_master" {
  source      = "./modules/proxmox_vm"
  name        = "k3s-master"
  vm_id       = 100
  node_name   = var.proxmox_node
  template_id = var.template_vm_id
  cores       = 2
  memory      = 4096
  ip_address  = "192.168.1.104/24"
  gateway     = "192.168.1.1"
  ssh_key     = var.ssh_key
}

# 2. Workers K3s
module "k3s_workers" {
  count       = 2
  source      = "./modules/proxmox_vm"
  name        = "k3s-worker-${count.index + 1}"
  vm_id       = 110 + count.index
  node_name   = var.proxmox_node
  template_id = var.template_vm_id
  cores       = 4
  memory      = 8192
  ip_address  = "192.168.1.${105 + count.index}/24"
  gateway     = "192.168.1.1"
  ssh_key     = var.ssh_key
}

# 3. CI Runner
module "ci_runner" {
  source      = "./modules/proxmox_vm"
  name        = "ci-runner"
  vm_id       = 120
  node_name   = var.proxmox_node
  template_id = var.template_vm_id
  cores       = 2
  memory      = 4096
  ip_address  = "192.168.1.120/24"
  gateway     = "192.168.1.1"
  ssh_key     = var.ssh_key
}