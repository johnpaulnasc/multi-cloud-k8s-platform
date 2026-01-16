#!/bin/bash
# =============================================================================
# Multi-Cloud Kubernetes Platform - Setup Script
# =============================================================================
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Print banner
print_banner() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║       Multi-Cloud Kubernetes Platform - Setup Script          ║"
    echo "║                                                               ║"
    echo "║  AWS EKS + OCI OKE | Terraform | ArgoCD | GitOps             ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    local missing_tools=()

    # Required tools
    local tools=("terraform" "kubectl" "kustomize" "helm" "git")

    for tool in "${tools[@]}"; do
        if command_exists "$tool"; then
            log_success "$tool is installed"
        else
            missing_tools+=("$tool")
            log_warn "$tool is not installed"
        fi
    done

    # Optional tools
    if command_exists "aws"; then
        log_success "AWS CLI is installed"
    else
        log_warn "AWS CLI is not installed (required for AWS deployments)"
    fi

    if command_exists "oci"; then
        log_success "OCI CLI is installed"
    else
        log_warn "OCI CLI is not installed (required for OCI deployments)"
    fi

    if command_exists "argocd"; then
        log_success "ArgoCD CLI is installed"
    else
        log_warn "ArgoCD CLI is not installed (optional)"
    fi

    if [ ${#missing_tools[@]} -ne 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        echo ""
        echo "Install missing tools:"
        echo "  - Terraform: https://www.terraform.io/downloads"
        echo "  - kubectl: https://kubernetes.io/docs/tasks/tools/"
        echo "  - kustomize: https://kubectl.docs.kubernetes.io/installation/kustomize/"
        echo "  - Helm: https://helm.sh/docs/intro/install/"
        exit 1
    fi

    log_success "All required prerequisites are installed!"
}

# Setup AWS credentials
setup_aws() {
    log_info "Setting up AWS configuration..."

    if [ -f ~/.aws/credentials ]; then
        log_success "AWS credentials file exists"
    else
        log_warn "AWS credentials not found. Please run 'aws configure'"
    fi
}

# Setup OCI credentials
setup_oci() {
    log_info "Setting up OCI configuration..."

    if [ -f ~/.oci/config ]; then
        log_success "OCI config file exists"
    else
        log_warn "OCI config not found. Please run 'oci setup config'"
    fi
}

# Initialize Terraform
init_terraform() {
    local environment=$1
    local cloud=$2

    log_info "Initializing Terraform for $cloud/$environment..."

    cd "terraform/environments/$environment/$cloud"
    terraform init -upgrade
    cd - > /dev/null

    log_success "Terraform initialized for $cloud/$environment"
}

# Deploy infrastructure
deploy_infrastructure() {
    local environment=$1
    local cloud=$2

    log_info "Deploying infrastructure to $cloud/$environment..."

    cd "terraform/environments/$environment/$cloud"
    terraform plan -out=tfplan

    read -p "Do you want to apply this plan? (yes/no): " confirm
    if [ "$confirm" == "yes" ]; then
        terraform apply tfplan
        log_success "Infrastructure deployed to $cloud/$environment"
    else
        log_warn "Deployment cancelled"
    fi
    cd - > /dev/null
}

# Setup ArgoCD
setup_argocd() {
    local environment=$1

    log_info "Setting up ArgoCD for $environment..."

    # Apply ArgoCD manifests
    kustomize build "kubernetes/argocd/overlays/$environment" | kubectl apply -f -

    # Wait for ArgoCD to be ready
    log_info "Waiting for ArgoCD to be ready..."
    kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s

    # Get initial admin password
    log_info "ArgoCD initial admin password:"
    kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
    echo ""

    log_success "ArgoCD setup complete!"
}

# Configure kubectl context
configure_kubectl() {
    local cloud=$1
    local environment=$2

    log_info "Configuring kubectl for $cloud/$environment..."

    if [ "$cloud" == "aws" ]; then
        local cluster_name="multi-cloud-k8s-$environment"
        aws eks update-kubeconfig --region us-east-1 --name "$cluster_name"
    elif [ "$cloud" == "oci" ]; then
        log_warn "Please run the kubeconfig command from Terraform output"
    fi
}

# Main menu
show_menu() {
    echo ""
    echo "Select an option:"
    echo "  1) Check prerequisites"
    echo "  2) Initialize Terraform (all environments)"
    echo "  3) Deploy AWS infrastructure"
    echo "  4) Deploy OCI infrastructure"
    echo "  5) Setup ArgoCD"
    echo "  6) Full setup (AWS + ArgoCD)"
    echo "  7) Full setup (OCI + ArgoCD)"
    echo "  8) Exit"
    echo ""
}

# Main function
main() {
    print_banner

    while true; do
        show_menu
        read -p "Enter your choice [1-8]: " choice

        case $choice in
            1)
                check_prerequisites
                ;;
            2)
                for env in dev staging prod; do
                    for cloud in aws oci; do
                        init_terraform "$env" "$cloud" || true
                    done
                done
                ;;
            3)
                read -p "Select environment (dev/staging/prod): " env
                setup_aws
                init_terraform "$env" "aws"
                deploy_infrastructure "$env" "aws"
                configure_kubectl "aws" "$env"
                ;;
            4)
                read -p "Select environment (dev/staging/prod): " env
                setup_oci
                init_terraform "$env" "oci"
                deploy_infrastructure "$env" "oci"
                ;;
            5)
                read -p "Select environment (dev/staging/prod): " env
                setup_argocd "$env"
                ;;
            6)
                read -p "Select environment (dev/staging/prod): " env
                check_prerequisites
                setup_aws
                init_terraform "$env" "aws"
                deploy_infrastructure "$env" "aws"
                configure_kubectl "aws" "$env"
                setup_argocd "$env"
                ;;
            7)
                read -p "Select environment (dev/staging/prod): " env
                check_prerequisites
                setup_oci
                init_terraform "$env" "oci"
                deploy_infrastructure "$env" "oci"
                setup_argocd "$env"
                ;;
            8)
                log_info "Goodbye!"
                exit 0
                ;;
            *)
                log_error "Invalid option"
                ;;
        esac
    done
}

# Run main function
main "$@"
