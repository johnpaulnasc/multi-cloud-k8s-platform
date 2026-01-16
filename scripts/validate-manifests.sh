#!/bin/bash
# =============================================================================
# Multi-Cloud Kubernetes Platform - Validate Kubernetes Manifests
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

ERRORS=0

# Check if required tools are installed
check_tools() {
    local tools=("kustomize" "kubectl")

    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            log_error "$tool is required but not installed"
            exit 1
        fi
    done
}

# Validate Kustomize build
validate_kustomize() {
    local path=$1
    local name=$2

    log_info "Validating $name..."

    if kustomize build "$path" > /dev/null 2>&1; then
        log_success "$name - Kustomize build successful"
    else
        log_error "$name - Kustomize build failed"
        kustomize build "$path"
        ((ERRORS++))
    fi
}

# Validate with kubectl dry-run
validate_kubectl() {
    local path=$1
    local name=$2

    log_info "Validating $name with kubectl dry-run..."

    if kustomize build "$path" | kubectl apply --dry-run=client -f - > /dev/null 2>&1; then
        log_success "$name - kubectl dry-run successful"
    else
        log_warn "$name - kubectl dry-run failed (may need CRDs)"
    fi
}

# Main validation
main() {
    check_tools

    log_info "Starting Kubernetes manifest validation..."
    echo ""

    # Validate base manifests
    log_info "=== Base Manifests ==="
    validate_kustomize "kubernetes/base/namespaces" "Base Namespaces"
    validate_kustomize "kubernetes/base/rbac" "Base RBAC"
    validate_kustomize "kubernetes/base/network-policies" "Base Network Policies"
    validate_kustomize "kubernetes/base/resource-quotas" "Base Resource Quotas"

    echo ""
    log_info "=== App Example ==="
    validate_kustomize "kubernetes/apps/app-example/base" "App Example Base"
    for env in dev staging prod; do
        validate_kustomize "kubernetes/apps/app-example/overlays/$env" "App Example $env"
    done

    echo ""
    log_info "=== ArgoCD ==="
    for env in dev staging prod; do
        validate_kustomize "kubernetes/argocd/overlays/$env" "ArgoCD $env"
    done

    echo ""
    if [ $ERRORS -eq 0 ]; then
        log_success "All manifests validated successfully!"
        exit 0
    else
        log_error "$ERRORS validation error(s) found"
        exit 1
    fi
}

main "$@"
