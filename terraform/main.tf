terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.78"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_api_url
  api_token = "${var.proxmox_api_token_id}=${var.proxmox_api_token_secret}"
  insecure  = true
}

resource "proxmox_virtual_environment_vm" "k3s_master" {
  name      = "k3s-master"
  node_name = var.proxmox_node
  vm_id     = 100

  clone {
    vm_id = var.template_vm_id
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 4096
  }

  agent {
    enabled = true
  }

  initialization {
    ip_config {
      ipv4 {
        address = "192.168.1.104/24"
        gateway = "192.168.1.1"
      }
    }
    user_account {
      keys = [var.ssh_key]
    }
  }
}

resource "proxmox_virtual_environment_vm" "k3s_worker" {
  count     = 2
  name      = "k3s-worker-${count.index + 1}"
  node_name = var.proxmox_node
  vm_id     = 110 + count.index

  clone {
    vm_id = var.template_vm_id
  }

  cpu {
    cores = 4
  }

  memory {
    dedicated = 8192
  }

  agent {
    enabled = true
  }

  initialization {
    ip_config {
      ipv4 {
        address = "192.168.1.${105 + count.index}/24"
        gateway = "192.168.1.1"
      }
    }
    user_account {
      keys = [var.ssh_key]
    }
  }
}