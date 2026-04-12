PROXMOX_HOST     ?= root@192.168.1.103
ANSIBLE_DIR      = ansible
TERRAFORM_DIR    = terraform
INVENTORY        = $(ANSIBLE_DIR)/inventory.ini
VAULT_OPTS       = --ask-vault-pass

.PHONY: help all setup-auth setup-template terraform-init terraform-plan terraform-apply terraform-destroy k3s ssl longhorn adguard adguard-ingress portainer hosts ansible-all status clean

# ============================================
# Help
# ============================================
help: ## Show this help
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""

# ============================================
# Full deploy
# ============================================
all: setup-auth setup-template terraform-init terraform-apply ansible-all ## Run everything in order

# ============================================
# Proxmox setup (run on remote server)
# ============================================
setup-auth: ## Create Proxmox user, role and API token
	scp setup-auth.sh $(PROXMOX_HOST):~/setup-auth.sh
	ssh $(PROXMOX_HOST) "bash ~/setup-auth.sh"

setup-template: ## Create VM template with cloud-init on Proxmox
	scp setup-template.sh $(PROXMOX_HOST):~/setup-template.sh
	ssh $(PROXMOX_HOST) "bash ~/setup-template.sh"

# ============================================
# Terraform
# ============================================
terraform-init: ## Initialize Terraform providers
	cd $(TERRAFORM_DIR) && terraform init

terraform-plan: ## Preview infrastructure changes
	cd $(TERRAFORM_DIR) && terraform plan

terraform-apply: ## Create VMs on Proxmox
	cd $(TERRAFORM_DIR) && terraform apply -auto-approve

terraform-destroy: ## Destroy all VMs
	cd $(TERRAFORM_DIR) && terraform destroy -auto-approve

# ============================================
# Ansible playbooks (Helm-based)
# ============================================
ansible-all: k3s ssl longhorn adguard adguard-ingress portainer ## Run all Ansible playbooks in order

k3s: ## Install K3s on master and workers
	cd $(ANSIBLE_DIR) && ansible-playbook -i inventory.ini k3s.yml

ssl: ## Deploy Cert-Manager and ClusterIssuer (Helm)
	cd $(ANSIBLE_DIR) && ansible-playbook -i inventory.ini ssl.yml

longhorn: ## Deploy Longhorn storage + Ingress (Helm)
	cd $(ANSIBLE_DIR) && ansible-playbook -i inventory.ini longhorn.yml

adguard: ## Deploy AdGuard Home DNS server
	cd $(ANSIBLE_DIR) && ansible-playbook -i inventory.ini adguard.yml $(VAULT_OPTS)

adguard-ingress: ## Expose AdGuard UI with Ingress + SSL
	cd $(ANSIBLE_DIR) && ansible-playbook -i inventory.ini adguard-ingress.yml

portainer: ## Deploy Portainer CE + Ingress (Helm)
	cd $(ANSIBLE_DIR) && ansible-playbook -i inventory.ini portainer.yml

# ============================================
# Utils
# ============================================
status: ## Show cluster status
	ssh ubuntu@192.168.1.104 "sudo k3s kubectl get nodes -o wide && echo '---' && sudo k3s kubectl get pods -A && echo '---' && sudo k3s kubectl get helmcharts -A"

clean: terraform-destroy ## Destroy everything
	@echo "Infrastructure destroyed."
