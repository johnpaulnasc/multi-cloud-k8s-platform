# =============================================================================
# Development Environment - AWS EKS
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
    key            = "dev/aws/terraform.tfstate"
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
  environment = "dev"
  project     = "multi-cloud-k8s"

  common_tags = {
    Environment = local.environment
    Project     = local.project
    ManagedBy   = "terraform"
    Owner       = "platform-team"
  }
}

# -----------------------------------------------------------------------------
# VPC Module
# -----------------------------------------------------------------------------
module "vpc" {
  source = "../../../modules/vpc-aws"

  cluster_name       = "${local.project}-${local.environment}"
  vpc_cidr           = var.vpc_cidr
  az_count           = 2 # Dev uses 2 AZs for cost savings
  enable_nat_gateway = true
  single_nat_gateway = true # Single NAT for dev
  enable_flow_logs   = false

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
  endpoint_public_access  = true
  public_access_cidrs     = ["0.0.0.0/0"]

  enable_cluster_encryption = false # Disabled for dev
  cluster_log_retention_days = 7

  enabled_cluster_log_types = ["api", "audit"]

  node_groups = {
    general = {
      instance_types             = ["t3.medium"]
      capacity_type              = "SPOT" # Use spot for dev
      disk_size                  = 30
      desired_size               = 2
      max_size                   = 4
      min_size                   = 1
      max_unavailable_percentage = 50
      labels = {
        workload = "general"
      }
      taints = []
    }
  }

  enable_vpc_cni_addon    = true
  enable_coredns_addon    = true
  enable_kube_proxy_addon = true
  enable_ebs_csi_driver   = true

  tags = local.common_tags
}
