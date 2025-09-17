#!/bin/bash

# Terraform Deployment Script
# Usage: ./deploy.sh [environment] [action]
# Example: ./deploy.sh dev plan
# Example: ./deploy.sh prod apply

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT=${1:-dev}
ACTION=${2:-plan}
PROJECT_NAME="network-automation"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install AWS CLI first."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    print_success "Prerequisites check passed!"
}

# Function to validate environment
validate_environment() {
    if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
        print_error "Invalid environment: $ENVIRONMENT"
        print_error "Valid environments: dev, staging, prod"
        exit 1
    fi
    
    if [[ ! -f "environments/$ENVIRONMENT/terraform.tfvars" ]]; then
        print_error "Environment configuration file not found: environments/$ENVIRONMENT/terraform.tfvars"
        exit 1
    fi
}

# Function to initialize Terraform
terraform_init() {
    print_status "Initializing Terraform..."
    terraform init -upgrade
    print_success "Terraform initialized!"
}

# Function to validate Terraform configuration
terraform_validate() {
    print_status "Validating Terraform configuration..."
    terraform validate
    terraform fmt -check=true -recursive
    print_success "Terraform configuration is valid!"
}

# Function to run Terraform plan
terraform_plan() {
    print_status "Running Terraform plan for $ENVIRONMENT environment..."
    terraform plan \
        -var-file="environments/$ENVIRONMENT/terraform.tfvars" \
        -out="$ENVIRONMENT.tfplan"
    print_success "Terraform plan completed!"
}

# Function to run Terraform apply
terraform_apply() {
    print_status "Running Terraform apply for $ENVIRONMENT environment..."
    
    if [[ "$ENVIRONMENT" == "prod" ]]; then
        print_warning "You are about to deploy to PRODUCTION environment!"
        read -p "Are you sure you want to continue? (yes/no): " -r
        if [[ ! $REPLY =~ ^yes$ ]]; then
            print_status "Deployment cancelled."
            exit 0
        fi
    fi
    
    terraform apply "$ENVIRONMENT.tfplan"
    print_success "Terraform apply completed!"
}

# Function to run Terraform destroy
terraform_destroy() {
    print_warning "You are about to DESTROY infrastructure in $ENVIRONMENT environment!"
    print_warning "This action cannot be undone!"
    read -p "Type 'destroy' to confirm: " -r
    
    if [[ $REPLY != "destroy" ]]; then
        print_status "Destroy cancelled."
        exit 0
    fi
    
    terraform destroy \
        -var-file="environments/$ENVIRONMENT/terraform.tfvars" \
        -auto-approve
    print_success "Infrastructure destroyed!"
}

# Function to show Terraform output
terraform_output() {
    print_status "Showing Terraform outputs..."
    terraform output
}

# Function to run security check
security_check() {
    print_status "Running security checks..."
    
    # Check if checkov is installed
    if command -v checkov &> /dev/null; then
        terraform plan -var-file="environments/$ENVIRONMENT/terraform.tfvars" -out=plan.out
        terraform show -json plan.out | checkov -f -
    else
        print_warning "Checkov not installed. Skipping security checks."
    fi
}

# Function to generate documentation
generate_docs() {
    print_status "Generating documentation..."
    
    # Check if terraform-docs is installed
    if command -v terraform-docs &> /dev/null; then
        terraform-docs markdown table --output-file TERRAFORM.md .
        for module in modules/*/; do
            terraform-docs markdown table --output-file README.md "$module"
        done
        print_success "Documentation generated!"
    else
        print_warning "terraform-docs not installed. Skipping documentation generation."
    fi
}

# Main execution
main() {
    print_status "Starting $ACTION for $ENVIRONMENT environment..."
    
    # Check prerequisites
    check_prerequisites
    
    # Validate environment
    validate_environment
    
    # Initialize Terraform
    terraform_init
    
    # Validate configuration
    terraform_validate
    
    # Execute requested action
    case $ACTION in
        "plan")
            terraform_plan
            ;;
        "apply")
            terraform_plan
            terraform_apply
            terraform_output
            ;;
        "destroy")
            terraform_destroy
            ;;
        "output")
            terraform_output
            ;;
        "security")
            security_check
            ;;
        "docs")
            generate_docs
            ;;
        *)
            print_error "Invalid action: $ACTION"
            print_error "Valid actions: plan, apply, destroy, output, security, docs"
            exit 1
            ;;
    esac
    
    print_success "Operation completed successfully!"
}

# Show usage if no arguments provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 [environment] [action]"
    echo ""
    echo "Environments: dev, staging, prod"
    echo "Actions: plan, apply, destroy, output, security, docs"
    echo ""
    echo "Examples:"
    echo "  $0 dev plan        # Plan development environment"
    echo "  $0 prod apply      # Apply production environment"
    echo "  $0 dev destroy     # Destroy development environment"
    echo "  $0 dev output      # Show outputs"
    echo "  $0 dev security    # Run security checks"
    echo "  $0 dev docs        # Generate documentation"
    exit 1
fi

# Run main function
main
