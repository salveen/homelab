.DEFAULT_GOAL := help
SHELL := /bin/bash

TF_DIR_PROXMOX := terraform/proxmox
TF_DIR_CF      := terraform/cloudflare
KUBECONFIG     ?= $(HOME)/.kube/homelab-config
export KUBECONFIG

## ---------- meta ----------

help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z_-]+:.*##/ { printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

## ---------- local dev ----------

tools: ## Install Mac dev tools via Homebrew
	brew bundle

precommit-install: ## Install git pre-commit hooks
	pre-commit install

precommit-run: ## Run pre-commit on all files
	pre-commit run --all-files

## ---------- terraform ----------

tf-init: ## terraform init (proxmox + cloudflare)
	cd $(TF_DIR_PROXMOX) && terraform init
	cd $(TF_DIR_CF)      && terraform init

plan: ## terraform plan (proxmox)
	cd $(TF_DIR_PROXMOX) && terraform plan

apply: ## terraform apply (proxmox)
	cd $(TF_DIR_PROXMOX) && terraform apply

cf-plan: ## terraform plan (cloudflare)
	cd $(TF_DIR_CF) && terraform plan

cf-apply: ## terraform apply (cloudflare)
	cd $(TF_DIR_CF) && terraform apply

## ---------- ansible ----------

inventory: ## Build ansible/inventory.yml from terraform output
	@cd $(TF_DIR_PROXMOX) && terraform output -json node_ips \
	  | jq '{all:{vars:{ansible_user:"ubuntu",ansible_ssh_private_key_file:"~/.ssh/id_ed25519",ansible_python_interpreter:"/usr/bin/python3"},children:{control_plane:{hosts:{"k3s-cp-1":{ansible_host:.["k3s-cp-1"][1][0]}}},workers:{hosts:{"k3s-wk-1":{ansible_host:.["k3s-wk-1"][1][0]},"k3s-wk-2":{ansible_host:.["k3s-wk-2"][1][0]}}},k3s_cluster:{children:{control_plane:null,workers:null}}}}}' \
	  | yq -P > ../../ansible/inventory.yml
	@echo "Wrote ansible/inventory.yml — ready for make bootstrap."

bootstrap: ## Run ansible bootstrap playbook
	cd ansible && ansible-playbook playbooks/bootstrap.yml

k3s-install: ## Run ansible k3s playbook
	cd ansible && ansible-playbook playbooks/k3s.yml

kubeconfig: ## Pull kubeconfig from cp-1 to $(KUBECONFIG)
	scp ubuntu@$$(cd $(TF_DIR_PROXMOX) && terraform output -raw cp1_ip):/etc/rancher/k3s/k3s.yaml $(KUBECONFIG)
	@sed -i.bak "s/127.0.0.1/$$(cd $(TF_DIR_PROXMOX) && terraform output -raw cp1_ip)/" $(KUBECONFIG) && rm $(KUBECONFIG).bak
	@chmod 600 $(KUBECONFIG)
	@echo "Wrote $(KUBECONFIG). Use: export KUBECONFIG=$(KUBECONFIG)"

## ---------- argocd ----------

argocd-bootstrap: ## Install ArgoCD via Helm and apply root-app
	helm repo add argo https://argoproj.github.io/argo-helm
	helm repo update
	kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
	helm upgrade --install argocd argo/argo-cd \
	  --namespace argocd \
	  --values kubernetes/bootstrap/argocd-values.yaml
	kubectl apply -f kubernetes/argocd/root-app.yaml

argocd-password: ## Print the initial ArgoCD admin password
	@kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d && echo

argocd-port-forward: ## Port-forward the ArgoCD UI to localhost:8080
	kubectl -n argocd port-forward svc/argocd-server 8080:443

## ---------- lint ----------

lint: ## Lint everything
	cd $(TF_DIR_PROXMOX) && terraform fmt -check -recursive && tflint
	cd $(TF_DIR_CF)      && terraform fmt -check -recursive && tflint
	yamllint -s ansible kubernetes .github
	find kubernetes -name '*.yaml' -o -name '*.yml' | xargs kubeconform -summary -skip CustomResourceDefinition

fmt: ## Auto-format Terraform
	terraform fmt -recursive terraform/

## ---------- danger zone ----------

destroy: ## Destroy the proxmox VMs (DESTRUCTIVE)
	cd $(TF_DIR_PROXMOX) && terraform destroy
