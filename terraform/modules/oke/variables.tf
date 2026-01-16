# =============================================================================
# OCI OKE Module Variables
# =============================================================================

variable "compartment_id" {
  description = "OCI Compartment ID"
  type        = string
}

variable "cluster_name" {
  description = "Name of the OKE cluster"
  type        = string
}

variable "vcn_id" {
  description = "ID of the VCN"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version (null for latest)"
  type        = string
  default     = null
}

variable "cluster_type" {
  description = "Type of OKE cluster (BASIC_CLUSTER or ENHANCED_CLUSTER)"
  type        = string
  default     = "ENHANCED_CLUSTER"
}

variable "cni_type" {
  description = "CNI type for the cluster (FLANNEL_OVERLAY or OCI_VCN_IP_NATIVE)"
  type        = string
  default     = "OCI_VCN_IP_NATIVE"
}

variable "is_public_endpoint" {
  description = "Whether the API endpoint should be public"
  type        = bool
  default     = true
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "api_endpoint_nsg_ids" {
  description = "List of NSG IDs for the API endpoint"
  type        = list(string)
  default     = []
}

variable "worker_nsg_ids" {
  description = "List of NSG IDs for worker nodes"
  type        = list(string)
  default     = []
}

variable "pods_cidr" {
  description = "CIDR block for pods"
  type        = string
  default     = "10.244.0.0/16"
}

variable "services_cidr" {
  description = "CIDR block for services"
  type        = string
  default     = "10.96.0.0/16"
}

variable "enable_kubernetes_dashboard" {
  description = "Enable Kubernetes Dashboard"
  type        = bool
  default     = false
}

variable "enable_pod_security_policy" {
  description = "Enable Pod Security Policy"
  type        = bool
  default     = false
}

variable "ssh_public_key" {
  description = "SSH public key for node access"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Node Pools
# -----------------------------------------------------------------------------
variable "node_pools" {
  description = "Map of node pool configurations"
  type = map(object({
    node_shape              = string
    is_flex_shape           = bool
    ocpus                   = number
    memory_in_gbs           = number
    node_count              = number
    boot_volume_size_in_gbs = number
    image_id                = string
    max_pods_per_node       = number
    node_labels             = map(string)
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# Virtual Node Pools (Serverless)
# -----------------------------------------------------------------------------
variable "virtual_node_pools" {
  description = "Map of virtual node pool configurations"
  type = map(object({
    pod_shape   = string
    size        = number
    node_labels = map(string)
    taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
