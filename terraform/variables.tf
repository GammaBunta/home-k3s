variable "proxmox_api_url" {}
variable "proxmox_api_token_id" {}
variable "proxmox_api_token_secret" { sensitive = true }
variable "proxmox_node" { default = "pve" }
variable "template_vm_id" {}
variable "ssh_key" { type = string}