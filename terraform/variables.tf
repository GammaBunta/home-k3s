variable "proxmox_api_url" { 
    type = string 
}
variable "proxmox_api_token_id" { 
    type = string 
}
variable "proxmox_api_token_secret" { 
    type = string
     sensitive = true 
}
variable "proxmox_node" { 
    type = string
    default = "pve" 
}

variable "template_vm_id" { 
  type        = number
  description = "VM ID of the template to clone"
}

variable "ssh_key" {
  type    = string
  description = "Path to the SSH public key to be added to the VMs for authentication."
}