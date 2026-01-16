# Multi-Cloud Kubernetes Platform

[![CI](https://github.com/johnpaulnasc/multi-cloud-k8s-platform/actions/workflows/ci.yaml/badge.svg)](https://github.com/johnpaulnasc/multi-cloud-k8s-platform/actions/workflows/ci.yaml)
[![Terraform](https://img.shields.io/badge/Terraform-1.6+-purple.svg)](https://www.terraform.io/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.29+-blue.svg)](https://kubernetes.io/)

A production-ready multi-cloud Kubernetes platform supporting **AWS EKS** and **Oracle Cloud Infrastructure (OCI) OKE** with GitOps deployment using ArgoCD.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        Multi-Cloud Kubernetes Platform                      │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────┐         ┌─────────────────────────┐            │
│  │        AWS EKS          │         │       OCI OKE           │            │
│  │  ┌───────────────────┐  │         │  ┌───────────────────┐  │            │
│  │  │   Control Plane   │  │         │  │   Control Plane   │  │            │
│  │  └───────────────────┘  │         │  └───────────────────┘  │            │
│  │  ┌───────────────────┐  │         │  ┌───────────────────┐  │            │
│  │  │   Worker Nodes    │  │         │  │   Worker Nodes    │  │            │
│  │  │  ┌─────┐ ┌─────┐  │  │         │  │  ┌─────┐ ┌─────┐  │  │            │
│  │  │  │ Pod │ │ Pod │  │  │         │  │  │ Pod │ │ Pod │  │  │            │
│  │  │  └─────┘ └─────┘  │  │         │  │  └─────┘ └─────┘  │  │            │
│  │  └───────────────────┘  │         │  └───────────────────┘  │            │
│  └─────────────────────────┘         └─────────────────────────┘            │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                        GitOps (ArgoCD)                              │    │
│  │     ┌─────────────┐  ┌─────────────┐  ┌─────────────┐               │    │
│  │     │     Dev     │  │   Staging   │  │    Prod     │               │    │
│  │     │ Auto-Sync   │  │ Auto-Sync   │  │ Manual-Sync │               │    │
│  │     └─────────────┘  └─────────────┘  └─────────────┘               │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Features

- **Multi-Cloud Support**: Deploy to AWS EKS and OCI OKE
- **Infrastructure as Code**: Terraform modules for reproducible deployments
- **GitOps**: ArgoCD for declarative application delivery
- **Environment Management**: Separate configurations for dev, staging, and prod
- **Security**: Network policies, RBAC, pod security, and secrets encryption
- **Full Observability Stack**: Prometheus, Grafana, Loki, Jaeger, AlertManager
- **Cross-Cloud Dashboards**: Compare metrics between AWS and OCI clusters
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
│       ├── prometheus/       # Metrics collection
│       ├── grafana/          # Visualization & dashboards
│       ├── loki/             # Log aggregation
│       ├── jaeger/           # Distributed tracing
│       └── alertmanager/     # Alerting
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
| Security Scan | Push/PR/Weekly | Trivy, Checkov, TFSec, Kubesec, Gitleaks |
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

The platform implements defense-in-depth security with multiple layers of protection.

### Security Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Security Layers                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                    Admission Control (OPA Gatekeeper)               │    │
│  │  • Required labels • Container limits • Allowed repos • Probes     │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                     Pod Security Standards                          │    │
│  │  • Restricted (prod) • Baseline (staging) • Privileged (system)    │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                     Network Policies                                │    │
│  │  • Default deny • Namespace isolation • Egress control             │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                     RBAC (Per Environment)                          │    │
│  │  • Dev: developers full access • Staging: QA + viewers             │    │
│  │  • Prod: SRE only + read-only for devs                             │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │              Secrets Management (External Secrets + Vault)          │    │
│  │  • HashiCorp Vault • AWS Secrets Manager • OCI Vault               │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                  Vulnerability Scanning (Trivy)                     │    │
│  │  • Image scanning • Config auditing • Secret detection             │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Pod Security Standards

The platform enforces Kubernetes Pod Security Standards per namespace:

| Environment | Enforce | Audit | Warn |
|-------------|---------|-------|------|
| Production | `restricted` | `restricted` | `restricted` |
| Staging | `baseline` | `restricted` | `restricted` |
| Development | `baseline` | `baseline` | `restricted` |
| System (kube-system, etc.) | `privileged` | `privileged` | `privileged` |

### Network Policies

- **Default deny**: All ingress/egress blocked unless explicitly allowed
- **Namespace isolation**: Pods can only communicate within their namespace by default
- **Controlled egress**: DNS, HTTPS, and cloud metadata access allowed
- **Cross-namespace rules**: Monitoring and ArgoCD namespaces have specific access

Deploy network policies:
```bash
kustomize build kubernetes/security/network-policies | kubectl apply -f -
```

### OPA Gatekeeper Policies

Admission control policies enforce security at deployment time:

| Policy | Enforcement | Description |
|--------|-------------|-------------|
| `block-privileged-containers` | Deny | Prevents privileged containers |
| `block-host-namespace` | Deny | Prevents hostNetwork, hostPID, hostIPC |
| `require-run-as-nonroot` | Deny | Requires runAsNonRoot: true |
| `require-readonly-rootfs` | Warn | Recommends read-only root filesystem |
| `block-latest-tag` | Deny | Blocks :latest image tag |
| `require-probes` | Warn/Deny | Requires liveness/readiness probes |
| `allowed-repos` | Deny | Restricts container registries |
| `container-limits` | Deny | Requires resource limits |
| `required-labels` | Deny | Enforces standard labels |

Deploy Gatekeeper policies:
```bash
kustomize build kubernetes/security/gatekeeper | kubectl apply -f -
```

### RBAC (Role-Based Access Control)

Granular RBAC per environment following principle of least privilege:

**Cluster Roles:**
- `platform-admin` - Full cluster access
- `security-auditor` - Read-only security resources
- `monitoring-viewer` - View metrics and monitoring data

**Namespace Roles:**
- `namespace-operator` - Full namespace control
- `namespace-developer` - Deploy and manage workloads
- `namespace-viewer` - Read-only access

**Environment Permissions:**
| Role | Dev | Staging | Prod |
|------|-----|---------|------|
| Developers | Full (operator) | Read-only | Read-only |
| QA Team | Viewer | Full (developer) | Read-only |
| SRE Team | Operator | Operator | Full (operator) |
| On-Call | - | Developer | Developer |

Deploy RBAC:
```bash
# Per environment
kustomize build kubernetes/security/rbac/dev | kubectl apply -f -
kustomize build kubernetes/security/rbac/staging | kubectl apply -f -
kustomize build kubernetes/security/rbac/prod | kubectl apply -f -
```

### Secrets Management

The platform uses External Secrets Operator integrated with multiple secret backends:

**Supported Backends:**
- HashiCorp Vault (recommended)
- AWS Secrets Manager
- OCI Vault

**Example ExternalSecret:**
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: database-credentials
  namespace: prod
spec:
  refreshInterval: 15m
  secretStoreRef:
    name: vault-backend
    kind: ClusterSecretStore
  target:
    name: database-credentials
  data:
    - secretKey: DB_PASSWORD
      remoteRef:
        key: prod/database
        property: password
```

Deploy External Secrets:
```bash
kustomize build kubernetes/security/external-secrets/overlays/prod | kubectl apply -f -
```

### Vulnerability Scanning (Trivy)

Continuous security scanning with Trivy Operator:

- **Image vulnerabilities**: Scans all container images
- **Config auditing**: Detects misconfigurations
- **Secret detection**: Finds exposed secrets in images

View vulnerability reports:
```bash
# List all vulnerability reports
kubectl get vulnerabilityreports -A

# Get detailed report
kubectl describe vulnerabilityreport <name> -n <namespace>

# List config audit reports
kubectl get configauditreports -A
```

### Security Scanning CI/CD

The platform includes automated security scanning in GitHub Actions:

| Scanner | Target | Description |
|---------|--------|-------------|
| **Trivy** | IaC | Terraform and Kubernetes misconfigurations |
| **Checkov** | IaC | Policy-as-code security checks |
| **TFSec** | Terraform | Terraform-specific security analysis |
| **Kubesec** | Kubernetes | Kubernetes manifest security scoring |
| **Gitleaks** | Repository | Secret detection in code |
| **TruffleHog** | Repository | Verified secret detection |

Security scan results are uploaded to GitHub Security tab (SARIF format).

Run security scan manually:
```bash
# Trigger workflow
gh workflow run security-scan.yaml
```

### Security Hardening Checklist

- [ ] Enable Pod Security Standards for all namespaces
- [ ] Deploy OPA Gatekeeper with all constraint templates
- [ ] Configure network policies for all namespaces
- [ ] Set up RBAC per environment
- [ ] Integrate External Secrets Operator with Vault
- [ ] Enable Trivy vulnerability scanning
- [ ] Configure security scanning in CI/CD
- [ ] Enable audit logging on clusters
- [ ] Configure secrets encryption at rest (KMS/OCI Vault)
- [ ] Implement image signing and verification

## Observability Stack

The platform includes a comprehensive observability stack for metrics, logs, traces, and alerting.

### Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Observability Stack                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐   │
│  │ Prometheus  │    │    Loki     │    │   Jaeger    │    │ Alertmanager│   │
│  │  (Metrics)  │    │   (Logs)    │    │  (Traces)   │    │  (Alerts)   │   │
│  └──────┬──────┘    └──────┬──────┘    └──────┬──────┘    └──────┬──────┘   │
│         │                  │                  │                  │          │
│         └──────────────────┴──────────────────┴──────────────────┘          │
│                                    │                                        │
│                            ┌───────▼───────┐                                │
│                            │    Grafana    │                                │
│                            │ (Dashboards)  │                                │
│                            └───────────────┘                                │
│                                                                             │
│  Data Collection:                                                           │
│  ┌─────────────┐    ┌─────────────┐    ┌──────────────┐                     │
│  │Node Exporter│    │  Promtail   │    │OTel Collector│                     │
│  │   (Nodes)   │    │   (Logs)    │    │  (Traces)    │                     │
│  └─────────────┘    └─────────────┘    └──────────────┘                     │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Components

| Component | Description | Port |
|-----------|-------------|------|
| **Prometheus** | Metrics collection and storage | 9090 |
| **Grafana** | Visualization and dashboards | 3000 |
| **Loki** | Log aggregation (like Prometheus for logs) | 3100 |
| **Promtail** | Log collection agent (DaemonSet) | 9080 |
| **Jaeger** | Distributed tracing | 16686 |
| **OTel Collector** | OpenTelemetry trace processing | 4317/4318 |
| **Alertmanager** | Alert routing and notifications | 9093 |
| **kube-state-metrics** | Kubernetes object metrics | 8080 |
| **node-exporter** | Node-level metrics | 9100 |

### Grafana Dashboards

| Dashboard | Description |
|-----------|-------------|
| **Kubernetes Cluster Overview** | Nodes, pods, CPU, memory, namespaces |
| **Multi-Cloud Overview** | Cross-cloud comparison (AWS vs OCI) |
| **Application Metrics (RED)** | Rate, Errors, Duration per service |
| **Logs Explorer** | Search and analyze logs from Loki |
| **Tracing Overview** | Distributed traces from Jaeger |

### Alert Rules

The platform includes pre-configured alerts for:

**Infrastructure Alerts:**
- `NodeNotReady` - Node is not ready for 5+ minutes
- `NodeHighCPU` - CPU usage above 85%
- `NodeHighMemory` - Memory usage above 85%
- `NodeDiskFull` - Disk usage above 90%

**Pod/Deployment Alerts:**
- `PodCrashLooping` - Pod restarting frequently
- `PodNotReady` - Pod not ready for 10+ minutes
- `ContainerOOMKilled` - Container killed due to OOM
- `DeploymentReplicasMismatch` - Desired vs available replicas

**SLO-Based Alerts:**
- `HighErrorRate` - Error rate above 5%
- `HighLatency` - p95 latency above 1 second
- `LowAvailability` - Availability below 99.9%

**Multi-Cloud Alerts:**
- `CloudProviderDown` - No nodes detected for a cloud provider
- `CrossCloudLatencyHigh` - High latency between clouds

### Deploy Observability Stack

**Via ArgoCD (Recommended):**
```bash
# The monitoring stack is automatically deployed via app-of-apps
kubectl apply -f kubernetes/argocd/base/applications/app-of-apps.yaml
```

**Manual Deployment:**
```bash
# Deploy entire stack
kustomize build kubernetes/monitoring | kubectl apply -f -

# Or deploy individual components
kustomize build kubernetes/monitoring/prometheus/base | kubectl apply -f -
kustomize build kubernetes/monitoring/grafana/base | kubectl apply -f -
kustomize build kubernetes/monitoring/loki/base | kubectl apply -f -
kustomize build kubernetes/monitoring/jaeger/base | kubectl apply -f -
kustomize build kubernetes/monitoring/alertmanager/base | kubectl apply -f -
```

### Access Dashboards

```bash
# Grafana (default: admin/admin123!)
kubectl port-forward svc/grafana -n monitoring 3000:3000

# Prometheus
kubectl port-forward svc/prometheus -n monitoring 9090:9090

# Jaeger UI
kubectl port-forward svc/jaeger-query -n monitoring 16686:16686

# Alertmanager
kubectl port-forward svc/alertmanager -n monitoring 9093:9093
```

### Configure Alerting

Update `kubernetes/monitoring/alertmanager/base/alertmanager-config.yaml` with your notification channels:

```yaml
receivers:
  - name: 'slack-alerts'
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/YOUR/WEBHOOK/URL'
        channel: '#alerts'

  - name: 'pagerduty-critical'
    pagerduty_configs:
      - service_key: 'YOUR_PAGERDUTY_KEY'
```

### Instrument Your Applications

**For metrics (Prometheus):**
```yaml
# Add annotations to your pods
annotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "8080"
  prometheus.io/path: "/metrics"
```

**For tracing (OpenTelemetry):**
```yaml
env:
  - name: OTEL_EXPORTER_OTLP_ENDPOINT
    value: "http://otel-collector.monitoring:4317"
  - name: OTEL_SERVICE_NAME
    value: "my-service"
```

**For logs (Loki/Promtail):**
- Logs are automatically collected from stdout/stderr
- Use structured logging (JSON) for better querying
- Add labels via pod annotations for filtering

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
