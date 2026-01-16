# =============================================================================
# Staging Environment - OCI Variables
# =============================================================================

variable "tenancy_ocid" {
  description = "OCI Tenancy OCID"
  type        = string
}

variable "user_ocid" {
  description = "OCI User OCID"
  type        = string
}

variable "fingerprint" {
  description = "OCI API Key Fingerprint"
  type        = string
}

variable "private_key_path" {
  description = "Path to OCI API Private Key"
  type        = string
}

variable "oci_region" {
  description = "OCI Region"
  type        = string
  default     = "us-ashburn-1"
}

variable "compartment_id" {
  description = "OCI Compartment ID"
  type        = string
}

variable "vcn_cidr" {
  description = "CIDR block for VCN"
  type        = string
  default     = "10.40.0.0/16"
}

variable "kubernetes_version" {
  description = "Kubernetes version (null for latest)"
  type        = string
  default     = null
}

variable "ssh_public_key" {
  description = "SSH public key for node access"
  type        = string
  default     = ""
}

variable "node_image_id" {
  description = "OCID of the node image"
  type        = string
}
