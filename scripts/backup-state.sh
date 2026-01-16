#!/bin/bash
# =============================================================================
# Multi-Cloud Kubernetes Platform - Backup Terraform State Script
# =============================================================================
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

BACKUP_DIR="backups/terraform-state"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

backup_state() {
    local environment=$1
    local cloud=$2
    local state_file="terraform/environments/$environment/$cloud/terraform.tfstate"
    local backup_file="$BACKUP_DIR/${cloud}_${environment}_${TIMESTAMP}.tfstate"

    if [ -f "$state_file" ]; then
        mkdir -p "$BACKUP_DIR"
        cp "$state_file" "$backup_file"
        log_success "Backed up $cloud/$environment state to $backup_file"
    else
        log_info "No local state file found for $cloud/$environment (using remote backend)"
    fi
}

export_remote_state() {
    local environment=$1
    local cloud=$2
    local backup_file="$BACKUP_DIR/${cloud}_${environment}_${TIMESTAMP}.tfstate"

    log_info "Exporting state for $cloud/$environment..."

    cd "terraform/environments/$environment/$cloud"
    terraform state pull > "../../../$backup_file"
    cd - > /dev/null

    if [ -s "$backup_file" ]; then
        log_success "Exported state to $backup_file"
    else
        log_error "Failed to export state for $cloud/$environment"
    fi
}

main() {
    mkdir -p "$BACKUP_DIR"

    log_info "Starting Terraform state backup..."

    for env in dev staging prod; do
        for cloud in aws oci; do
            if [ -d "terraform/environments/$env/$cloud" ]; then
                export_remote_state "$env" "$cloud" || backup_state "$env" "$cloud"
            fi
        done
    done

    # Clean up old backups (keep last 10)
    log_info "Cleaning up old backups..."
    ls -t "$BACKUP_DIR"/*.tfstate 2>/dev/null | tail -n +11 | xargs -r rm

    log_success "Backup complete! Files stored in $BACKUP_DIR"
}

main "$@"
