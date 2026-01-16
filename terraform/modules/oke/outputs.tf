# =============================================================================
# OCI OKE Module Outputs
# =============================================================================

output "cluster_id" {
  description = "ID of the OKE cluster"
  value       = oci_containerengine_cluster.main.id
}

output "cluster_name" {
  description = "Name of the OKE cluster"
  value       = oci_containerengine_cluster.main.name
}

output "cluster_kubernetes_version" {
  description = "Kubernetes version of the cluster"
  value       = oci_containerengine_cluster.main.kubernetes_version
}

output "cluster_endpoints" {
  description = "Endpoints of the OKE cluster"
  value       = oci_containerengine_cluster.main.endpoints
}

output "cluster_state" {
  description = "State of the OKE cluster"
  value       = oci_containerengine_cluster.main.state
}

output "node_pools" {
  description = "Map of node pools created"
  value = {
    for k, v in oci_containerengine_node_pool.main : k => {
      id                 = v.id
      kubernetes_version = v.kubernetes_version
      node_shape         = v.node_shape
    }
  }
}

output "virtual_node_pools" {
  description = "Map of virtual node pools created"
  value = {
    for k, v in oci_containerengine_virtual_node_pool.main : k => {
      id   = v.id
      size = v.size
    }
  }
}

# -----------------------------------------------------------------------------
# Kubeconfig Helper
# -----------------------------------------------------------------------------
output "kubeconfig_command" {
  description = "OCI CLI command to create kubeconfig"
  value       = "oci ce cluster create-kubeconfig --cluster-id ${oci_containerengine_cluster.main.id} --file $HOME/.kube/config --region ${var.compartment_id} --token-version 2.0.0"
}
