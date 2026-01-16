# =============================================================================
# Development Environment - OCI Outputs
# =============================================================================

output "cluster_id" {
  description = "ID of the OKE cluster"
  value       = module.oke.cluster_id
}

output "cluster_name" {
  description = "Name of the OKE cluster"
  value       = module.oke.cluster_name
}

output "cluster_endpoints" {
  description = "Endpoints of the OKE cluster"
  value       = module.oke.cluster_endpoints
}

output "vcn_id" {
  description = "ID of the VCN"
  value       = module.vcn.vcn_id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.vcn.private_subnet_ids
}

output "kubeconfig_command" {
  description = "Command to create kubeconfig"
  value       = "oci ce cluster create-kubeconfig --cluster-id ${module.oke.cluster_id} --file $HOME/.kube/config --region ${var.oci_region} --token-version 2.0.0"
}
