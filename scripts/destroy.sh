#!/bin/bash
# =============================================================================
# Multi-Cloud Kubernetes Platform - Destroy Script
# =============================================================================
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

print_warning() {
    echo -e "${RED}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                        ⚠️  WARNING ⚠️                        ║"
    echo "║                                                               ║"
    echo "║   This script will DESTROY all infrastructure resources!      ║"
    echo "║   This action is IRREVERSIBLE!                                ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

destroy_infrastructure() {
    local environment=$1
    local cloud=$2

    log_warn "Destroying $cloud infrastructure in $environment environment..."

    cd "terraform/environments/$environment/$cloud"

    echo ""
    log_warn "Resources to be destroyed:"
    terraform plan -destroy -out=destroy.tfplan

    echo ""
    read -p "Type 'destroy' to confirm destruction of $cloud/$environment: " confirm

    if [ "$confirm" == "destroy" ]; then
        terraform apply destroy.tfplan
        log_success "Infrastructure destroyed for $cloud/$environment"
    else
        log_info "Destruction cancelled"
    fi

    cd - > /dev/null
}

cleanup_argocd() {
    log_info "Cleaning up ArgoCD resources..."

    # Delete all ArgoCD applications first
    kubectl delete applications --all -n argocd --ignore-not-found=true

    # Delete ArgoCD namespace
    kubectl delete namespace argocd --ignore-not-found=true

    log_success "ArgoCD cleanup complete"
}

main() {
    print_warning

    echo "Select what to destroy:"
    echo "  1) AWS Dev environment"
    echo "  2) AWS Staging environment"
    echo "  3) AWS Prod environment"
    echo "  4) OCI Dev environment"
    echo "  5) OCI Staging environment"
    echo "  6) OCI Prod environment"
    echo "  7) All AWS environments"
    echo "  8) All OCI environments"
    echo "  9) Everything (ALL environments)"
    echo "  10) Exit"
    echo ""

    read -p "Enter your choice [1-10]: " choice

    case $choice in
        1) destroy_infrastructure "dev" "aws" ;;
        2) destroy_infrastructure "staging" "aws" ;;
        3) destroy_infrastructure "prod" "aws" ;;
        4) destroy_infrastructure "dev" "oci" ;;
        5) destroy_infrastructure "staging" "oci" ;;
        6) destroy_infrastructure "prod" "oci" ;;
        7)
            for env in dev staging prod; do
                destroy_infrastructure "$env" "aws"
            done
            ;;
        8)
            for env in dev staging prod; do
                destroy_infrastructure "$env" "oci"
            done
            ;;
        9)
            read -p "Are you ABSOLUTELY SURE you want to destroy EVERYTHING? (yes/no): " final_confirm
            if [ "$final_confirm" == "yes" ]; then
                cleanup_argocd
                for env in prod staging dev; do
                    for cloud in aws oci; do
                        destroy_infrastructure "$env" "$cloud" || true
                    done
                done
            fi
            ;;
        10)
            log_info "Goodbye!"
            exit 0
            ;;
        *)
            log_error "Invalid option"
            ;;
    esac
}

main "$@"
