# Multi-Cloud Kubernetes Platform

[![CI](https://github.com/johnpaulnasc/multi-cloud-k8s-platform/actions/workflows/ci.yaml/badge.svg)](https://github.com/johnpaulnasc/multi-cloud-k8s-platform/actions/workflows/ci.yaml)
[![Terraform](https://img.shields.io/badge/Terraform-1.6+-purple.svg)](https://www.terraform.io/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.29+-blue.svg)](https://kubernetes.io/)

A production-ready multi-cloud Kubernetes platform supporting **AWS EKS** and **Oracle Cloud Infrastructure (OCI) OKE** with GitOps deployment using ArgoCD.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        Multi-Cloud Kubernetes Platform                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────┐         ┌─────────────────────────┐           │
│  │        AWS EKS          │         │       OCI OKE           │           │
│  │  ┌───────────────────┐  │         │  ┌───────────────────┐  │           │
│  │  │   Control Plane   │  │         │  │   Control Plane   │  │           │
│  │  └───────────────────┘  │         │  └───────────────────┘  │           │
│  │  ┌───────────────────┐  │         │  ┌───────────────────┐  │           │
│  │  │   Worker Nodes    │  │         │  │   Worker Nodes    │  │           │
│  │  │  ┌─────┐ ┌─────┐  │  │         │  │  ┌─────┐ ┌─────┐  │  │           │
│  │  │  │ Pod │ │ Pod │  │  │         │  │  │ Pod │ │ Pod │  │  │           │
│  │  │  └─────┘ └─────┘  │  │         │  │  └─────┘ └─────┘  │  │           │
│  │  └───────────────────┘  │         │  └───────────────────┘  │           │
│  └─────────────────────────┘         └─────────────────────────┘           │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                           GitOps (ArgoCD)                           │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                  │   │
│  │  │     Dev     │  │   Staging   │  │    Prod     │                  │   │
│  │  │ Auto-Sync   │  │ Auto-Sync   │  │ Manual-Sync │                  │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘                  │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Features

- **Multi-Cloud Support**: Deploy to AWS EKS and OCI OKE
- **Infrastructure as Code**: Terraform modules for reproducible deployments
- **GitOps**: ArgoCD for declarative application delivery
- **Environment Management**: Separate configurations for dev, staging, and prod
- **Security**: Network policies, RBAC, pod security, and secrets encryption
- **Observability Ready**: Pre-configured for Prometheus, Grafana, and AlertManager
- **CI/CD**: GitHub Actions workflows for automation
- **Cost Optimization**: Spot instances support for non-production environments

## Project Structure

```
multi-cloud-k8s-platform/
├── terraform/
│   ├── modules/
│   │   ├── eks/            # AWS EKS module
│   │   ├── oke/            # OCI OKE module
│   │   ├── vpc-aws/        # AWS VPC module
│   │   └── vcn-oci/        # OCI VCN module
│   └── environments/
│       ├── dev/
│       │   ├── aws/
│       │   └── oci/
│       ├── staging/
│       │   ├── aws/
│       │   └── oci/
│       └── prod/
│           ├── aws/
│           └── oci/
├── kubernetes/
│   ├── base/
│   │   ├── namespaces/
│   │   ├── rbac/
│   │   ├── network-policies/
│   │   └── resource-quotas/
│   ├── apps/
│   │   └── app-example/
│   │       ├── base/
│   │       └── overlays/
│   │           ├── dev/
│   │           ├── staging/
│   │           └── prod/
│   ├── argocd/
│   │   ├── base/
│   │   └── overlays/
│   └── monitoring/
├── scripts/
│   ├── setup.sh
│   ├── destroy.sh
│   ├── install-tools.sh
│   └── validate-manifests.sh
├── .github/
│   └── workflows/
│       ├── ci.yaml
│       ├── terraform-plan.yaml
│       ├── terraform-apply.yaml
│       ├── kubernetes-validate.yaml
│       └── argocd-sync.yaml
└── docs/
```

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.5.0
- [kubectl](https://kubernetes.io/docs/tasks/tools/) >= 1.28
- [Kustomize](https://kubectl.docs.kubernetes.io/installation/kustomize/) >= 5.0
- [Helm](https://helm.sh/docs/intro/install/) >= 3.0
- [AWS CLI](https://aws.amazon.com/cli/) >= 2.0 (for AWS deployments)
- [OCI CLI](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm) >= 3.0 (for OCI deployments)

### Install Tools

```bash
# Use the provided script to install all tools
./scripts/install-tools.sh
```

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/johnpaulnasc/multi-cloud-k8s-platform.git
cd multi-cloud-k8s-platform
```

### 2. Configure Cloud Credentials

**AWS:**
```bash
aws configure
# Or use IAM roles with OIDC for GitHub Actions
```

**OCI:**
```bash
oci setup config
# Follow the prompts to configure OCI CLI
```

### 3. Deploy Infrastructure

**Using the setup script (recommended):**
```bash
./scripts/setup.sh
```

**Manual deployment:**

```bash
# Initialize Terraform
cd terraform/environments/dev/aws
terraform init

# Plan the deployment
terraform plan -out=tfplan

# Apply the changes
terraform apply tfplan

# Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name multi-cloud-k8s-dev
```

### 4. Deploy ArgoCD

```bash
# Apply ArgoCD manifests
kustomize build kubernetes/argocd/overlays/dev | kubectl apply -f -

# Wait for ArgoCD to be ready
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s

# Get the initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port forward to access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

### 5. Deploy Applications

```bash
# Apply the app-of-apps pattern
kubectl apply -f kubernetes/argocd/base/applications/app-of-apps.yaml
```

## Environment Configuration

### Development (dev)
- 2 Availability Zones
- Single NAT Gateway (cost optimization)
- Spot instances for worker nodes
- Minimal resource allocation
- Auto-sync enabled in ArgoCD

### Staging
- 3 Availability Zones
- Single NAT Gateway
- Mix of On-Demand and Spot instances
- Medium resource allocation
- Auto-sync enabled in ArgoCD

### Production (prod)
- 3 Availability Zones
- HA NAT Gateways (one per AZ)
- On-Demand instances only
- Full resource allocation
- Private API endpoint
- Manual sync in ArgoCD
- Full logging and monitoring

## Terraform Modules

### AWS EKS Module

```hcl
module "eks" {
  source = "./modules/eks"

  cluster_name       = "my-cluster"
  kubernetes_version = "1.29"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  node_groups = {
    general = {
      instance_types = ["t3.large"]
      capacity_type  = "ON_DEMAND"
      desired_size   = 3
      max_size       = 10
      min_size       = 2
    }
  }
}
```

### OCI OKE Module

```hcl
module "oke" {
  source = "./modules/oke"

  compartment_id = var.compartment_id
  cluster_name   = "my-cluster"
  vcn_id         = module.vcn.vcn_id

  node_pools = {
    general = {
      node_shape    = "VM.Standard.E4.Flex"
      is_flex_shape = true
      ocpus         = 4
      memory_in_gbs = 32
      node_count    = 3
    }
  }
}
```

## GitOps with ArgoCD

### Application Structure

Applications follow the **app-of-apps pattern**:

```yaml
# kubernetes/argocd/base/applications/app-of-apps.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: app-of-apps
  namespace: argocd
spec:
  project: platform
  source:
    repoURL: https://github.com/johnpaulnasc/multi-cloud-k8s-platform.git
    targetRevision: HEAD
    path: kubernetes/argocd/base/applications
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### Adding New Applications

1. Create base manifests in `kubernetes/apps/your-app/base/`
2. Create overlays for each environment in `kubernetes/apps/your-app/overlays/`
3. Create ArgoCD Application manifests in `kubernetes/argocd/overlays/*/applications/`
4. Push changes and ArgoCD will automatically sync (for dev/staging)

## CI/CD Workflows

### Available Workflows

| Workflow | Trigger | Description |
|----------|---------|-------------|
| CI | Push/PR | Linting, security scans, validation |
| Terraform Plan | PR to terraform/ | Plan infrastructure changes |
| Terraform Apply | Merge to main | Apply infrastructure changes |
| Kubernetes Validate | PR to kubernetes/ | Validate K8s manifests |
| ArgoCD Sync | Manual | Trigger ArgoCD sync |
| Release | Tag push | Create GitHub release |

### Required Secrets

Configure these secrets in your GitHub repository:

**AWS:**
- `AWS_ROLE_ARN` - IAM role ARN for OIDC authentication

**OCI:**
- `OCI_CLI_USER` - OCI user OCID
- `OCI_CLI_TENANCY` - OCI tenancy OCID
- `OCI_CLI_FINGERPRINT` - API key fingerprint
- `OCI_CLI_KEY_CONTENT` - API private key content
- `OCI_CLI_REGION` - OCI region
- `OCI_COMPARTMENT_ID` - Compartment OCID
- `OCI_NODE_IMAGE_ID` - Node image OCID

**ArgoCD:**
- `ARGOCD_SERVER` - ArgoCD server URL
- `ARGOCD_ADMIN_PASSWORD` - ArgoCD admin password

## Security

### Network Security

- Default deny network policies
- Namespace isolation
- Ingress/Egress rules per application

### RBAC

- Cluster-wide roles: `platform-admin`, `platform-developer`, `platform-viewer`
- Project-scoped roles in ArgoCD
- Principle of least privilege

### Secrets Management

- Kubernetes Secrets encryption at rest (AWS KMS / OCI Vault)
- External Secrets Operator support (optional)

## Monitoring & Observability

The platform is pre-configured for:

- **Prometheus** - Metrics collection
- **Grafana** - Visualization
- **AlertManager** - Alerting
- **Loki** - Log aggregation (optional)

Deploy monitoring stack:

```bash
kubectl apply -f kubernetes/monitoring/
```

## Troubleshooting

### Common Issues

**Terraform state lock:**
```bash
terraform force-unlock <lock-id>
```

**ArgoCD out of sync:**
```bash
argocd app sync <app-name> --force
```

**kubectl context issues:**
```bash
# AWS
aws eks update-kubeconfig --region <region> --name <cluster-name>

# OCI
oci ce cluster create-kubeconfig --cluster-id <cluster-id> --file ~/.kube/config
```

### Useful Commands

```bash
# Check cluster status
kubectl get nodes
kubectl get pods -A

# Check ArgoCD applications
argocd app list
argocd app get <app-name>

# View logs
kubectl logs -f deployment/<name> -n <namespace>

# Validate manifests locally
./scripts/validate-manifests.sh
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

**John Paul Nascimento**
- GitHub: [@johnpaulnasc](https://github.com/johnpaulnasc)

## Acknowledgments

- [Terraform AWS EKS Module](https://github.com/terraform-aws-modules/terraform-aws-eks)
- [ArgoCD](https://argo-cd.readthedocs.io/)
- [Kustomize](https://kustomize.io/)
