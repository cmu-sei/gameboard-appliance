# Makefile for developing IMCITE proxmox

TF_ARGS := -auto-approve
HOST ?= 0

.PHONY: console port-forward init check-workspace init confirm-deploy apply

console:
	@aws ssm start-session --target $$(terraform output -json instance_id | jq -r '.[$(HOST)]') \
						   --document-name AWS-StartInteractiveCommand \
						   --parameters '{"command":["sudo -i -u admin"]}' \
						   --profile proxmox

port-forward:
	@echo "proxmox web console: https://localhost:8006"; \
	echo "credentials: $(shell terraform output proxmox_creds)"; \
	aws ssm start-session --target $$(terraform output -json instance_id | jq -r '.[0]') \
						   --document-name AWS-StartPortForwardingSession \
						   --parameters '{"portNumber":["8006"], "localPortNumber":["8006"]}' \
						   --profile proxmox

deploy: init check-workspace confirm-deploy apply

init:
	@if [ -f tfstate.config ]; then \
		terraform init -backend-config=./tfstate.config; \
	else \
		terraform init; \
	fi; \

check-workspace:
	@CURRENT_WORKSPACE=$$(terraform workspace show); \
	if [ "$$CURRENT_WORKSPACE" = "default" ]; then \
		echo "Currently in 'default' workspace. Choose a new workspace for development."; \
		read -p "Enter a new/existing workspace name: " NEW_WORKSPACE; \
		if terraform workspace list | grep -q "  $$NEW_WORKSPACE$$"; then \
			echo "Switching to existing workspace '$$NEW_WORKSPACE'..."; \
			terraform workspace select "$$NEW_WORKSPACE"; \
		else \
			echo "Creating and switching to new workspace '$$NEW_WORKSPACE'..."; \
			terraform workspace new "$$NEW_WORKSPACE"; \
		fi; \
	else \
		read -p "Currently in workspace '$$CURRENT_WORKSPACE'. Continue? [y/N] " CONFIRM; \
		if [ "$$(echo $$CONFIRM | tr '[:upper:]' '[:lower:]')" != "y" ]; then \
			echo "Aborting."; \
			exit 1; \
		fi; \
	fi

confirm-deploy:
	@CURRENT_WORKSPACE=$$(terraform workspace show); \
	read -p "Deploy proxmox development environment to '$$CURRENT_WORKSPACE'? [y/N] " CONFIRM; \
	if [ "$$(echo $$CONFIRM | tr '[:upper:]' '[:lower:]')" != "y" ]; then \
		echo "Aborting."; \
		exit 1; \
	fi

apply:
	@terraform apply $(TF_ARGS)
