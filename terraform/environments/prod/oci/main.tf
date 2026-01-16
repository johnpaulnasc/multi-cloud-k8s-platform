# =============================================================================
# Production Environment - OCI OKE
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
  }

  backend "s3" {
    bucket                      = "multi-cloud-k8s-tfstate"
    key                         = "prod/oci/terraform.tfstate"
    region                      = "us-ashburn-1"
    endpoint                    = "https://<namespace>.compat.objectstorage.us-ashburn-1.oraclecloud.com"
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    force_path_style            = true
  }
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.oci_region
}

locals {
  environment = "prod"
  project     = "multi-cloud-k8s"

  common_tags = {
    Environment = local.environment
    Project     = local.project
    ManagedBy   = "terraform"
    Owner       = "platform-team"
    CostCenter  = "production"
  }
}

# -----------------------------------------------------------------------------
# VCN Module
# -----------------------------------------------------------------------------
module "vcn" {
  source = "../../../modules/vcn-oci"

  compartment_id = var.compartment_id
  cluster_name   = "${local.project}-${local.environment}"
  vcn_cidr       = var.vcn_cidr
  subnet_count   = 3

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# OKE Module
# -----------------------------------------------------------------------------
module "oke" {
  source = "../../../modules/oke"

  compartment_id     = var.compartment_id
  cluster_name       = "${local.project}-${local.environment}"
  vcn_id             = module.vcn.vcn_id
  kubernetes_version = var.kubernetes_version
  cluster_type       = "ENHANCED_CLUSTER"

  cni_type           = "OCI_VCN_IP_NATIVE"
  is_public_endpoint = var.is_public_endpoint

  public_subnet_ids    = module.vcn.public_subnet_ids
  private_subnet_ids   = module.vcn.private_subnet_ids
  api_endpoint_nsg_ids = [module.vcn.api_endpoint_nsg_id]
  worker_nsg_ids       = [module.vcn.worker_nsg_id]

  pods_cidr     = "10.244.0.0/16"
  services_cidr = "10.96.0.0/16"

  enable_kubernetes_dashboard = false
  enable_pod_security_policy  = false

  ssh_public_key = var.ssh_public_key

  node_pools = {
    system = {
      node_shape              = "VM.Standard.E4.Flex"
      is_flex_shape           = true
      ocpus                   = 4
      memory_in_gbs           = 32
      node_count              = 3
      boot_volume_size_in_gbs = 100
      image_id                = var.node_image_id
      max_pods_per_node       = 31
      node_labels = {
        workload = "system"
        "node.kubernetes.io/purpose" = "system"
      }
    }
    general = {
      node_shape              = "VM.Standard.E4.Flex"
      is_flex_shape           = true
      ocpus                   = 8
      memory_in_gbs           = 64
      node_count              = 5
      boot_volume_size_in_gbs = 200
      image_id                = var.node_image_id
      max_pods_per_node       = 31
      node_labels = {
        workload = "general"
      }
    }
    memory-optimized = {
      node_shape              = "VM.Standard.E4.Flex"
      is_flex_shape           = true
      ocpus                   = 8
      memory_in_gbs           = 128
      node_count              = 2
      boot_volume_size_in_gbs = 200
      image_id                = var.node_image_id
      max_pods_per_node       = 31
      node_labels = {
        workload = "memory-optimized"
      }
    }
  }

  virtual_node_pools = var.enable_virtual_nodes ? {
    serverless = {
      pod_shape   = "Pod.Standard.E4.Flex"
      size        = 10
      node_labels = {
        workload = "serverless"
      }
      taints = [{
        key    = "virtual-node"
        value  = "true"
        effect = "NoSchedule"
      }]
    }
  } : {}

  tags = local.common_tags
}
