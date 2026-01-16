#!/bin/bash
# =============================================================================
# Multi-Cloud Kubernetes Platform - Install Tools Script
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

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/debian_version ]; then
            OS="debian"
        elif [ -f /etc/redhat-release ]; then
            OS="redhat"
        else
            OS="linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    else
        log_error "Unsupported OS: $OSTYPE"
        exit 1
    fi
    log_info "Detected OS: $OS"
}

# Install Terraform
install_terraform() {
    log_info "Installing Terraform..."

    TERRAFORM_VERSION="1.6.0"

    if [[ "$OS" == "macos" ]]; then
        brew tap hashicorp/tap
        brew install hashicorp/tap/terraform
    else
        wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
        sudo apt update && sudo apt install terraform
    fi

    log_success "Terraform installed: $(terraform version | head -1)"
}

# Install kubectl
install_kubectl() {
    log_info "Installing kubectl..."

    if [[ "$OS" == "macos" ]]; then
        brew install kubectl
    else
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
        rm kubectl
    fi

    log_success "kubectl installed: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
}

# Install Kustomize
install_kustomize() {
    log_info "Installing Kustomize..."

    if [[ "$OS" == "macos" ]]; then
        brew install kustomize
    else
        curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
        sudo mv kustomize /usr/local/bin/
    fi

    log_success "Kustomize installed: $(kustomize version)"
}

# Install Helm
install_helm() {
    log_info "Installing Helm..."

    if [[ "$OS" == "macos" ]]; then
        brew install helm
    else
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    fi

    log_success "Helm installed: $(helm version --short)"
}

# Install AWS CLI
install_aws_cli() {
    log_info "Installing AWS CLI..."

    if [[ "$OS" == "macos" ]]; then
        brew install awscli
    else
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip awscliv2.zip
        sudo ./aws/install
        rm -rf aws awscliv2.zip
    fi

    log_success "AWS CLI installed: $(aws --version)"
}

# Install OCI CLI
install_oci_cli() {
    log_info "Installing OCI CLI..."

    bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)" -- --accept-all-defaults

    log_success "OCI CLI installed"
}

# Install ArgoCD CLI
install_argocd_cli() {
    log_info "Installing ArgoCD CLI..."

    ARGOCD_VERSION="v2.10.0"

    if [[ "$OS" == "macos" ]]; then
        brew install argocd
    else
        curl -sSL -o argocd "https://github.com/argoproj/argo-cd/releases/download/$ARGOCD_VERSION/argocd-linux-amd64"
        chmod +x argocd
        sudo mv argocd /usr/local/bin/
    fi

    log_success "ArgoCD CLI installed: $(argocd version --client | head -1)"
}

# Install k9s
install_k9s() {
    log_info "Installing k9s..."

    if [[ "$OS" == "macos" ]]; then
        brew install k9s
    else
        curl -sS https://webinstall.dev/k9s | bash
    fi

    log_success "k9s installed"
}

# Main menu
show_menu() {
    echo ""
    echo "Select tools to install:"
    echo "  1) Terraform"
    echo "  2) kubectl"
    echo "  3) Kustomize"
    echo "  4) Helm"
    echo "  5) AWS CLI"
    echo "  6) OCI CLI"
    echo "  7) ArgoCD CLI"
    echo "  8) k9s"
    echo "  9) All tools"
    echo "  10) Exit"
    echo ""
}

main() {
    detect_os

    while true; do
        show_menu
        read -p "Enter your choice [1-10]: " choice

        case $choice in
            1) install_terraform ;;
            2) install_kubectl ;;
            3) install_kustomize ;;
            4) install_helm ;;
            5) install_aws_cli ;;
            6) install_oci_cli ;;
            7) install_argocd_cli ;;
            8) install_k9s ;;
            9)
                install_terraform
                install_kubectl
                install_kustomize
                install_helm
                install_aws_cli
                install_oci_cli
                install_argocd_cli
                install_k9s
                ;;
            10)
                log_info "Goodbye!"
                exit 0
                ;;
            *)
                log_error "Invalid option"
                ;;
        esac
    done
}

main "$@"
