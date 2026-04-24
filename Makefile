# Variables
TF_DIR = terraform
ANSIBLE_DIR = ansible
ANSIBLE_INVENTORY = inventory.ini
ANSIBLE_PLAYBOOK = site.yml
# On suppose que tu crées le .vault_pass à la racine, donc Ansible (qui sera dans son dossier) devra remonter d'un cran (../)
VAULT_PASS_FILE = ../.vault_pass

.PHONY: help tf-init tf-plan tf-apply ansible-deploy deploy destroy kubeconfig

help:
	@echo "Commandes disponibles :"
	@echo "  make deploy         - Lance tout : Terraform puis Ansible"
	@echo "  make tf-apply       - Lance uniquement Terraform (Création VMs)"
	@echo "  make ansible-deploy - Lance uniquement Ansible (Configuration K3s & Tailscale)"
	@echo "  make destroy        - /!\\ DETRUIT toute l'infrastructure /!\\"
	@echo "  make tf-reset       - Supprime l'état local Terraform (sans toucher aux VMs)"
	@echo "  make kubeconfig     - Récupère le kubeconfig du master pour k9s"

# 1. Commandes Terraform (utilisation de -chdir pour pointer vers le dossier terraform)
tf-init:
	terraform -chdir=$(TF_DIR) init

tf-plan: tf-init
	terraform -chdir=$(TF_DIR) plan

tf-apply: tf-init
	terraform -chdir=$(TF_DIR) apply -auto-approve

# 2. Commandes Ansible (on se place dans le dossier ansible pour qu'il trouve bien les roles et group_vars)
ansible-deploy:
	cd $(ANSIBLE_DIR) && ansible-playbook -i $(ANSIBLE_INVENTORY) $(ANSIBLE_PLAYBOOK) --vault-password-file $(VAULT_PASS_FILE)

# 3. Le combo ultime : Terraform + Ansible
deploy: tf-apply
	@echo "Attente de 15 secondes pour le démarrage complet des VMs..."
	@sleep 15
	$(MAKE) ansible-deploy

# 4. Pour tout casser proprement
destroy:
	terraform -chdir=$(TF_DIR) destroy

# 6. Kubeconfig pour k9s
kubeconfig:
	ssh ubuntu@192.168.1.104 "sudo cat /etc/rancher/k3s/k3s.yaml" \
		| sed 's/127.0.0.1/192.168.1.104/g' \
		> ~/.kube/config-home-k3s
	@echo "Kubeconfig prêt : export KUBECONFIG=~/.kube/config-home-k3s"

# 5. Reset local Terraform (supprime état + cache, sans toucher aux VMs)
tf-reset:
	rm -rf $(TF_DIR)/.terraform $(TF_DIR)/.terraform.lock.hcl
	rm -f $(TF_DIR)/terraform.tfstate $(TF_DIR)/terraform.tfstate.backup
	@echo "Reset local Terraform effectué. Lance 'make tf-apply' pour recréer."