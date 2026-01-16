# =============================================================================
# Staging Environment - AWS EKS
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
    key            = "staging/aws/terraform.tfstate"
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
  environment = "staging"
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
  az_count           = 3
  enable_nat_gateway = true
  single_nat_gateway = true # Single NAT for staging (cost vs HA)
  enable_flow_logs   = true
  flow_logs_retention_days = 14

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
  public_access_cidrs     = var.public_access_cidrs

  enable_cluster_encryption  = true
  cluster_log_retention_days = 14

  enabled_cluster_log_types = ["api", "audit", "authenticator"]

  node_groups = {
    general = {
      instance_types             = ["t3.large"]
      capacity_type              = "ON_DEMAND"
      disk_size                  = 50
      desired_size               = 3
      max_size                   = 6
      min_size                   = 2
      max_unavailable_percentage = 33
      labels = {
        workload = "general"
      }
      taints = []
    }
    spot = {
      instance_types             = ["t3.large", "t3.xlarge", "m5.large"]
      capacity_type              = "SPOT"
      disk_size                  = 50
      desired_size               = 2
      max_size                   = 10
      min_size                   = 0
      max_unavailable_percentage = 50
      labels = {
        workload = "spot"
      }
      taints = [{
        key    = "spot"
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
