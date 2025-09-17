# Network Automation Terraform Makefile
# Usage: make [target] ENV=[environment]

.PHONY: help init plan apply destroy output clean security docs cost-report

# Default environment
ENV ?= dev

# Colors for terminal output
YELLOW = \033[1;33m
GREEN = \033[0;32m
RED = \033[0;31m
NC = \033[0m # No Color

# Help target
help: ## Show this help message
	@echo "$(YELLOW)Network Automation Terraform Project$(NC)"
	@echo "$(YELLOW)======================================$(NC)"
	@echo ""
	@echo "$(GREEN)Available targets:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(GREEN)Usage examples:$(NC)"
	@echo "  make plan ENV=dev         # Plan development environment"
	@echo "  make apply ENV=prod       # Apply production environment"
	@echo "  make destroy ENV=dev      # Destroy development environment"
	@echo ""

init: ## Initialize Terraform
	@echo "$(YELLOW)Initializing Terraform...$(NC)"
	terraform init -upgrade

validate: ## Validate Terraform configuration
	@echo "$(YELLOW)Validating Terraform configuration...$(NC)"
	terraform validate
	terraform fmt -check=true -recursive

plan: validate ## Create Terraform execution plan
	@echo "$(YELLOW)Creating execution plan for $(ENV) environment...$(NC)"
	terraform plan -var-file="environments/$(ENV)/terraform.tfvars" -out="$(ENV).tfplan"

apply: plan ## Apply Terraform configuration
	@echo "$(YELLOW)Applying Terraform configuration for $(ENV) environment...$(NC)"
	@if [ "$(ENV)" = "prod" ]; then \
		echo "$(RED)WARNING: You are deploying to PRODUCTION!$(NC)"; \
		read -p "Are you sure? (yes/no): " confirm; \
		if [ "$$confirm" != "yes" ]; then \
			echo "$(RED)Deployment cancelled.$(NC)"; \
			exit 1; \
		fi; \
	fi
	terraform apply "$(ENV).tfplan"
	@echo "$(GREEN)Deployment completed successfully!$(NC)"

destroy: ## Destroy Terraform infrastructure
	@echo "$(RED)WARNING: This will destroy all infrastructure in $(ENV) environment!$(NC)"
	@read -p "Type 'destroy' to confirm: " confirm; \
	if [ "$$confirm" = "destroy" ]; then \
		terraform destroy -var-file="environments/$(ENV)/terraform.tfvars" -auto-approve; \
		echo "$(GREEN)Infrastructure destroyed.$(NC)"; \
	else \
		echo "$(RED)Destroy cancelled.$(NC)"; \
	fi

output: ## Show Terraform outputs
	@echo "$(YELLOW)Terraform outputs for $(ENV) environment:$(NC)"
	terraform output

clean: ## Clean up temporary files
	@echo "$(YELLOW)Cleaning up temporary files...$(NC)"
	rm -f *.tfplan
	rm -f plan.out
	rm -rf .terraform/
	find . -name "*.backup" -delete
	@echo "$(GREEN)Cleanup completed.$(NC)"

security: ## Run security checks
	@echo "$(YELLOW)Running security checks...$(NC)"
	@if command -v checkov >/dev/null 2>&1; then \
		terraform plan -var-file="environments/$(ENV)/terraform.tfvars" -out=plan.out; \
		terraform show -json plan.out | checkov -f -; \
	else \
		echo "$(RED)Checkov not installed. Install with: pip install checkov$(NC)"; \
	fi

docs: ## Generate documentation
	@echo "$(YELLOW)Generating documentation...$(NC)"
	@if command -v terraform-docs >/dev/null 2>&1; then \
		terraform-docs markdown table --output-file TERRAFORM.md .; \
		for module in modules/*/; do \
			terraform-docs markdown table --output-file README.md "$$module"; \
		done; \
		echo "$(GREEN)Documentation generated.$(NC)"; \
	else \
		echo "$(RED)terraform-docs not installed. Install from: https://terraform-docs.io/$(NC)"; \
	fi

cost-report: ## Generate cost report
	@echo "$(YELLOW)Generating cost report...$(NC)"
	@if command -v aws >/dev/null 2>&1; then \
		./scripts/cost-monitor.sh report; \
	else \
		echo "$(RED)AWS CLI not installed.$(NC)"; \
	fi

setup: ## Setup development environment
	@echo "$(YELLOW)Setting up development environment...$(NC)"
	@echo "Installing pre-commit hooks..."
	@if command -v pre-commit >/dev/null 2>&1; then \
		pre-commit install; \
	else \
		echo "$(RED)pre-commit not installed. Install with: pip install pre-commit$(NC)"; \
	fi
	@echo "$(GREEN)Development environment setup completed.$(NC)"

format: ## Format Terraform code
	@echo "$(YELLOW)Formatting Terraform code...$(NC)"
	terraform fmt -recursive

check-drift: ## Check for configuration drift
	@echo "$(YELLOW)Checking for configuration drift...$(NC)"
	terraform plan -var-file="environments/$(ENV)/terraform.tfvars" -detailed-exitcode

quick-deploy: ## Quick deployment (plan + apply)
	$(MAKE) plan ENV=$(ENV)
	$(MAKE) apply ENV=$(ENV)

status: ## Show infrastructure status
	@echo "$(YELLOW)Infrastructure Status for $(ENV) environment:$(NC)"
	@echo ""
	@echo "$(GREEN)Terraform State:$(NC)"
	@terraform show | head -20
	@echo ""
	@echo "$(GREEN)Outputs:$(NC)"
	@terraform output

# Environment-specific targets
dev: ## Deploy to development environment
	$(MAKE) apply ENV=dev

staging: ## Deploy to staging environment
	$(MAKE) apply ENV=staging

prod: ## Deploy to production environment
	$(MAKE) apply ENV=prod

# Default target
.DEFAULT_GOAL := help
