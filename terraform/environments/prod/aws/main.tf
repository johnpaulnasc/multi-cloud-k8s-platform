# =============================================================================
# Production Environment - AWS EKS
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    bucket         = "multi-cloud-k8s-tfstate"
    key            = "prod/aws/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
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
# VPC Module
# -----------------------------------------------------------------------------
module "vpc" {
  source = "../../../modules/vpc-aws"

  cluster_name       = "${local.project}-${local.environment}"
  vpc_cidr           = var.vpc_cidr
  az_count           = 3
  enable_nat_gateway = true
  single_nat_gateway = false # HA NAT Gateways in production
  enable_flow_logs   = true
  flow_logs_retention_days = 90

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# EKS Module
# -----------------------------------------------------------------------------
module "eks" {
  source = "../../../modules/eks"

  cluster_name        = "${local.project}-${local.environment}"
  kubernetes_version  = var.kubernetes_version
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  public_subnet_ids   = module.vpc.public_subnet_ids

  endpoint_private_access = true
  endpoint_public_access  = var.enable_public_access
  public_access_cidrs     = var.public_access_cidrs

  enable_cluster_encryption  = true
  cluster_log_retention_days = 90

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  node_groups = {
    system = {
      instance_types             = ["m5.large"]
      capacity_type              = "ON_DEMAND"
      disk_size                  = 100
      desired_size               = 3
      max_size                   = 6
      min_size                   = 3
      max_unavailable_percentage = 25
      labels = {
        workload = "system"
        "node.kubernetes.io/purpose" = "system"
      }
      taints = [{
        key    = "CriticalAddonsOnly"
        value  = "true"
        effect = "PREFER_NO_SCHEDULE"
      }]
    }
    general = {
      instance_types             = ["m5.xlarge", "m5a.xlarge"]
      capacity_type              = "ON_DEMAND"
      disk_size                  = 100
      desired_size               = 5
      max_size                   = 20
      min_size                   = 3
      max_unavailable_percentage = 25
      labels = {
        workload = "general"
      }
      taints = []
    }
    memory-optimized = {
      instance_types             = ["r5.xlarge", "r5a.xlarge"]
      capacity_type              = "ON_DEMAND"
      disk_size                  = 100
      desired_size               = 2
      max_size                   = 10
      min_size                   = 2
      max_unavailable_percentage = 25
      labels = {
        workload = "memory-optimized"
      }
      taints = [{
        key    = "memory-optimized"
        value  = "true"
        effect = "NO_SCHEDULE"
      }]
    }
  }

  enable_vpc_cni_addon    = true
  enable_coredns_addon    = true
  enable_kube_proxy_addon = true
  enable_ebs_csi_driver   = true

  tags = local.common_tags
}
