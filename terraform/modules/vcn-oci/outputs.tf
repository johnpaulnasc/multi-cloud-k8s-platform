# =============================================================================
# OCI VCN Module Outputs
# =============================================================================

output "vcn_id" {
  description = "ID of the VCN"
  value       = oci_core_vcn.main.id
}

output "vcn_cidr" {
  description = "CIDR block of the VCN"
  value       = oci_core_vcn.main.cidr_blocks[0]
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = oci_core_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = oci_core_subnet.private[*].id
}

output "api_endpoint_nsg_id" {
  description = "ID of the API endpoint network security group"
  value       = oci_core_network_security_group.api_endpoint.id
}

output "worker_nsg_id" {
  description = "ID of the worker network security group"
  value       = oci_core_network_security_group.worker.id
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = oci_core_nat_gateway.main.id
}

output "service_gateway_id" {
  description = "ID of the Service Gateway"
  value       = oci_core_service_gateway.main.id
}

output "availability_domains" {
  description = "Available availability domains"
  value       = local.ads
}
