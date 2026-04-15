# Homelab Kubernetes Platform — Infrastructure as Code

> Production-grade, self-hosted Kubernetes platform managed entirely as code.
> 4-node bare-metal cluster running a media, monitoring, DNS, and networking stack via
> Terraform + GitOps (Argo CD), with full CI/CD, security hardening, and backup automation.

![Terraform](https://img.shields.io/badge/Terraform-≥1.8-7B42BC?logo=terraform&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-1.29-326CE5?logo=kubernetes&logoColor=white)
![Helm](https://img.shields.io/badge/Helm-3-0F1689?logo=helm&logoColor=white)
![Argo CD](https://img.shields.io/badge/Argo_CD-GitOps-EF7B4D?logo=argo&logoColor=white)
![Prometheus](https://img.shields.io/badge/Prometheus-Grafana-E6522C?logo=prometheus&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-CI%2FCD-2088FF?logo=githubactions&logoColor=white)

---

## Overview

This repository contains the full Terraform configuration for a self-hosted homelab Kubernetes
cluster. It manages both platform infrastructure (ingress controller, monitoring stack, TLS
certificates) and application workloads (media server, DNS, torrent client) from a single,
version-controlled codebase.

**Key design goals:**
- Every resource is declared in code — no manual `kubectl apply` drift
- Platform infrastructure is Helm-managed via Terraform's Helm provider
- Application workloads that have an Argo CD owner are intentionally excluded from Terraform state (split controller ownership)
- Security-first defaults: Pod Security Standards, Network Policies, Resource Quotas, and Pod Disruption Budgets on every namespace
- Sensitive variables (`sensitive = true`) and a dedicated `secrets.auto.tfvars` (gitignored) keep secrets out of state diffs and version history

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  GitHub Repository (this repo)                                  │
│                                                                 │
│  .github/workflows/                                             │
│  ├── terraform-ci.yml    (fmt, validate, tflint, tfsec,         │
│  │                        kubeconform — runs on every PR/push)  │
│  └── terraform-plan.yml  (full plan against live cluster —      │
│                           self-hosted runner, manual dispatch)  │
└──────────────────────────────┬──────────────────────────────────┘
                               │ terraform apply
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│  Kubernetes Cluster  (4-node bare-metal, k8s v1.29)             │
│                                                                 │
│  Platform (Terraform-owned)         Apps (Argo CD-owned)        │
│  ├── ingress-nginx (Helm)           └── portfolio               │
│  ├── kube-prometheus-stack (Helm)                               │
│  ├── cert-manager (kubectl/manual)                              │
│  ├── metrics-server (Helm)                                      │
│  ├── Jellyfin                                                   │
│  ├── qBittorrent                                                │
│  ├── Pi-hole                                                    │
│  └── Network Policies / Resource Quotas / PDBs                  │
└─────────────────────────────────────────────────────────────────┘
```

### Controller Ownership Model

| Resource | Owned by | Rationale |
|---|---|---|
| Namespaces, RBAC, Network Policies | Terraform | Platform concerns — stable, long-lived |
| ingress-nginx, kube-prometheus-stack, Loki, Tempo, MinIO, Velero, Vault, External Secrets, metrics-server | Terraform | Infrastructure — needs version pinning and drift detection |
| Jellyfin, qBittorrent, Pi-hole | Terraform | No GitOps controller managing these |
| Portfolio workload (Deployment, Service, Ingress) | Argo CD | Argo CD tracks image updates; Terraform owns the namespace only |
| cert-manager | Unmanaged (manual) | Installed via kubectl with no Helm release secret; migration pending |
| Argo CD control-plane | Staged for Terraform | Module exists but disabled by default until live release import is completed |

---

## Tech Stack

| Layer | Technology |
|---|---|
| IaC | Terraform ≥ 1.8, `hashicorp/kubernetes` ~> 2.25, `hashicorp/helm` ~> 2.13 |
| Container Orchestration | Kubernetes 1.29 (bare-metal, kubeadm) |
| Ingress | ingress-nginx 4.15.1 (Helm-managed) |
| Monitoring | kube-prometheus-stack 82.18.0 — Prometheus, Grafana, Alertmanager, node-exporter, kube-state-metrics |
| Logging | Loki + Promtail (Helm module available, staged disabled by default) |
| Tracing | Grafana Tempo (Helm module available, staged disabled by default) |
| Backup/DR | MinIO (S3-compatible) + Velero (Helm modules available, staged disabled by default) |
| Secrets | HashiCorp Vault + External Secrets Operator (Helm modules available, staged disabled by default) |
| TLS | cert-manager v1.14.5 with self-signed CA chain (selfsigned-bootstrap → local-lan-ca) |
| GitOps | Argo CD (manages portfolio application; Terraform module staged for import) |
| CI/CD | GitHub Actions — tfsec, TFLint, kubeconform, self-hosted plan runner |
| DNS | Pi-hole (network-wide ad-blocking DNS) |
| Media | Jellyfin (self-hosted media server) |
| Node Metrics | metrics-server (enables `kubectl top`, HPA signals) |

---

## Project Structure

```
terraform/
├── main.tf                          # Root module — wires all modules together
├── variables.tf                     # All input variables with descriptions and validation
├── outputs.tf                       # Cluster and service outputs
├── provider.tf                      # kubernetes + helm providers
├── terraform.tfvars                 # Tunable settings (committed, no secrets)
├── secrets.auto.tfvars              # Sensitive values — gitignored
├── secrets.auto.tfvars.example      # Template for required secrets
├── backend.tf.example               # Remote state scaffold (kubernetes / S3+DynamoDB)
│
├── .github/workflows/
│   ├── terraform-ci.yml             # PR/push: fmt, validate, tflint, tfsec, kubeconform
│   └── terraform-plan.yml           # Manual: full plan against live cluster (self-hosted runner)
│
├── scripts/
│   ├── backup.sh                    # Snapshot state + cert-manager CA + Pi-hole config
│   ├── audit-ai-gpu.sh              # Inventory AI workloads + GPU capacity/requests from live cluster
│   ├── restore.sh                   # Restore from snapshot with dry-run mode
│   ├── setup-github-runner.sh       # Register/manage self-hosted GitHub Actions runner
│   ├── set-github-secret.sh         # Push KUBECONFIG_B64 secret via gh CLI
│   └── print-kubeconfig-b64.sh      # Encode kubeconfig for GitHub secret
│
└── modules/
    ├── cert-manager/                # Helm release + selfsigned-bootstrap + local-lan-ca issuers
    ├── argocd/                      # Helm release for Argo CD (staged for import)
    ├── external-secrets/            # Helm release + optional Vault ClusterSecretStore bootstrap
    ├── gpu-device-plugins/          # Intel/AMD/NVIDIA device plugins for GPU resource advertisement
    ├── ingress-nginx/               # Helm release, default IngressClass, metrics integration
    ├── kube-prometheus-stack/       # Helm release, Prometheus + Grafana + Alertmanager
    ├── loki/                        # Helm release for Loki + Promtail log aggregation
    ├── metrics-server/              # Kubernetes-native metrics-server resources
    ├── minio/                       # Helm release for in-cluster S3-compatible object storage
    ├── monitoring/                  # Ingress + network-allow rules for Grafana/Prometheus
    ├── networking/                  # Default-deny NetworkPolicy per namespace
    ├── network-policies/            # Per-app allow rules (ingress, DNS, metrics scrape)
    ├── resource-quotas/             # CPU/memory quotas per namespace
    ├── tempo/                       # Helm release for distributed trace storage (OTLP/Jaeger receivers)
    ├── pod-disruption-budgets/      # minAvailable PDBs for HA
    ├── portfolio/                   # Namespace-only (workload owned by Argo CD)
    ├── jellyfin/                    # Deployment, PVC, Service, Ingress, security hardening
    ├── qbittorrent/                 # Deployment, PVC, Service, Ingress
    ├── pihole/                      # Deployment, Service (DNS UDP/TCP + Web UI)
    ├── vault/                       # Helm release for Vault with persistent storage
    └── velero/                      # Helm release for backup/restore to S3-compatible backend
```

---

## Security Model

Every namespace gets the following by default (`enable_network_policies = true`):

1. **Default-deny ingress** NetworkPolicy — blocks all traffic not explicitly allowed
2. **Per-app allow rules** — explicit egress/ingress policies per workload (DNS, metrics scrape, HTTP ingress)
3. **Pod Security Standards** — each namespace is labelled with appropriate enforcement level (`baseline` or `privileged`)
4. **Resource Quotas** — CPU and memory limits prevent noisy-neighbour resource exhaustion
5. **Pod Disruption Budgets** — `minAvailable: 1` on all stateful workloads

Sensitive variables use `sensitive = true` and strong validation (e.g., `pihole_web_password`
enforces length, character complexity, and blocks weak defaults like `admin` or `changeme`).

---

## Quick Start

### Prerequisites

```bash
# Terraform ≥ 1.8
terraform --version

# kubectl configured and pointing at target cluster
kubectl cluster-info
kubectl get nodes
```

### 1. Clone and configure

```bash
git clone https://github.com/korabcenaj/terraform.git
cd terraform

# Copy and fill in secrets
cp secrets.auto.tfvars.example secrets.auto.tfvars
# Edit secrets.auto.tfvars — set pihole_web_password, grafana_admin_password
```

### 2. Initialize

```bash
terraform init
terraform validate
terraform fmt -recursive
```

### 3. Plan

```bash
terraform plan -out=tfplan
terraform show tfplan
```

### 4. Apply

```bash
terraform apply tfplan
```

### 5. Verify

```bash
kubectl get namespaces
kubectl get deployments -A
kubectl top nodes

# Grafana
kubectl port-forward -n monitoring svc/monitor-grafana 3000:80
# open http://localhost:3000

# Jellyfin
kubectl port-forward -n jellyfin svc/jellyfin 8096:8096
# open http://localhost:8096
```

## Portfolio Image Build To The Live Registry

The current live cluster has:

- a Docker distribution registry running in namespace `registry`
- a NodePort service on `30500`
- an Argo CD application (`portfoliosite`) syncing from `https://github.com/korabcenaj/portfolio-container.git`

The failing portfolio deployment is currently using an unqualified image reference:

```yaml
image: portfolio-web:latest
```

That resolves to Docker Hub, not the in-cluster registry, so pods stay in `ErrImagePull`.

Build and push the image from this repo with:

```bash
./scripts/build-portfolio-image.sh 192.168.1.10
```

If the machine driving the build does not have Docker, use the in-cluster Kaniko job instead:

```bash
./scripts/build-portfolio-image-kaniko.sh
```

That job builds from `https://github.com/korabcenaj/portfolio-container.git` inside Kubernetes and pushes to the live registry service at `registry.registry.svc.cluster.local:5000`. Workloads should still reference the external pull address such as `192.168.1.10:30500/portfolio-web:latest`.

If you omit the host, the script will derive the first node InternalIP via `kubectl` and push to:

```text
<node-internal-ip>:30500/portfolio-web:latest
```

For CI/CD, use the self-hosted GitHub Actions workflow in `.github/workflows/build-portfolio-image.yml`.
Set repository variable `PORTFOLIO_REGISTRY_HOST` to one of the node IPs that exposes the registry NodePort, or provide `KUBECONFIG_B64` so the workflow can derive it dynamically.

The Argo-managed manifest in the `korabcenaj/portfolio-container` repository must be updated to the fully qualified image reference emitted by the script or workflow, for example:

```yaml
image: 192.168.1.10:30500/portfolio-web:latest
```

Important: the current registry deployment has no PVC, so pushed images are ephemeral and will be lost if the registry pod is recreated.

### 6. Audit AI workloads and GPU nodes

```bash
# Produces reports/ai-gpu-audit-<timestamp>/ with summary + raw evidence files
scripts/audit-ai-gpu.sh

# Read the summary
cat reports/ai-gpu-audit-*/summary.md | tail -n 40
```

---

## Configuration

All tunable settings live in `terraform.tfvars`. Secrets go in `secrets.auto.tfvars` (gitignored).

```hcl
# Feature flags — everything is opt-in
enable_portfolio              = true
manage_portfolio_workload     = false  # Argo CD owns the workload; Terraform owns the namespace
enable_jellyfin               = true
enable_ingress_nginx          = true
enable_kube_prometheus_stack  = true
enable_gpu_device_plugins     = true
enable_network_policies       = true
enable_resource_quotas        = true
enable_pod_disruption_budgets = true

# All ingress FQDNs are derived from this base domain
ingress_base_domain           = "local.lan"

# Pin Helm chart versions to running cluster versions
ingress_nginx_chart_version         = "4.15.1"
kube_prometheus_stack_chart_version = "82.18.0"
```

Scale an application without editing files:

```bash
terraform apply -var="portfolio_replicas=2"
```

---

## CI/CD Pipelines

### Terraform CI ([.github/workflows/terraform-ci.yml](.github/workflows/terraform-ci.yml))

Runs on every pull request and push to `main`:

| Step | Tool | Purpose |
|---|---|---|
| Format check | `terraform fmt -check` | Enforce consistent style |
| Validate | `terraform validate` | Catch HCL syntax and type errors |
| Lint | `tflint --recursive` | Enforce Terraform best-practices |
| Security scan | `tfsec` | SAST for misconfigurations |
| Policy scan (report-only) | `checkov` | Policy-as-code visibility without blocking existing pipelines |
| Schema validation | `kubeconform` | Validate Kubernetes manifests against API schemas |

### Terraform Plan ([.github/workflows/terraform-plan.yml](.github/workflows/terraform-plan.yml))

Manual workflow run on a **self-hosted runner** inside the homelab network:
- Decodes `KUBECONFIG_B64` from GitHub Secrets and writes `~/.kube/config`
- Verifies cluster reachability before proceeding
- Requires either a local `terraform.tfstate` or a configured remote backend — prevents misleading empty-state plans

#### Self-hosted runner setup

```bash
# 1. Generate a runner token in GitHub → Settings → Actions → Runners
export GH_RUNNER_TOKEN=<token>
./scripts/setup-github-runner.sh install --service
```

Runner lifecycle:

```bash
./scripts/setup-github-runner.sh status | start | stop
./scripts/setup-github-runner.sh remove --token <removal-token>
```

Set the kubeconfig secret:

```bash
# Encode and upload in one step (requires gh CLI)
./scripts/set-github-secret.sh --name KUBECONFIG_B64

# Or encode manually
./scripts/print-kubeconfig-b64.sh
```

Install `gh` CLI if needed:

```bash
./scripts/install-gh.sh
gh auth login
```

---

## Remote State

The project ships with backend scaffolding for two backends. Neither is committed by default.

```bash
# Kubernetes secret backend (recommended for homelab)
cp backend.tf.example backend.tf
cp backend.kubernetes.hcl.example backend.kubernetes.hcl
terraform init -migrate-state -backend-config=backend.kubernetes.hcl
```

```hcl
# backend.tf
terraform {
  backend "kubernetes" {}
}
```

S3 + DynamoDB locking is available via `backend.s3.hcl.example` for cloud-backed teams.

---

## Backup and Restore

The backup script snapshots Terraform state (local and/or remote backend state when available), the cert-manager root CA secret, and Pi-hole config.

```bash
# Create snapshot
./scripts/backup.sh
# Output: backups/20260414-120000/

# Inspect backup metadata (includes terraform_state_source)
cat backups/latest/metadata.txt

# Dry-run restore (no writes)
./scripts/restore.sh --dry-run backups/20260414-120000

# Full restore
./scripts/restore.sh --yes backups/20260414-120000
```

Terraform state restore is intentionally manual to prevent accidental state overwrites.

---

## Common Commands

```bash
terraform init                           # Download providers (first time / after version changes)
terraform validate                       # Syntax and type check
terraform fmt -recursive                 # Format all .tf files
terraform plan -out=tfplan               # Dry-run, save plan
terraform apply tfplan                   # Apply saved plan
terraform state list                     # List all managed resources
terraform state show <resource>          # Inspect a specific resource
terraform state rm <resource>            # Remove from state without destroying
terraform import <resource> <id>         # Bring an existing resource under management
terraform output -json                   # Structured output
kubectl top nodes                        # Live node metrics (requires metrics-server)
```

---

## Extending the Platform

To add a new application:

1. Create `modules/<myapp>/` with `main.tf`, `variables.tf`, `outputs.tf`
2. Add `enable_myapp` variable to `variables.tf`
3. Create the namespace and module block in `main.tf`
4. Add the namespace to the `namespaces_with_policies` list in the `networking` module call
5. Add quota and PDB entries in the respective module calls

```bash
terraform plan -var="enable_myapp=true"
terraform apply -var="enable_myapp=true"
```

---

## Known Limitations

| Item | Status | Notes |
|---|---|---|
| cert-manager | Unmanaged | Installed via kubectl; no Helm release secret. Module exists (`modules/cert-manager/`) but is disabled (`enable_cert_manager = false`) pending safe migration. |
| Portfolio workload | Argo CD-owned | `manage_portfolio_workload = false` — Terraform owns the namespace and its labels; Argo CD owns the Deployment, Service, and Ingress. |
| Grafana admin password | Requires change | Default placeholder in `secrets.auto.tfvars` must be replaced before `terraform apply`. |
| Vault + External Secrets | Staged disabled | Modules are implemented but disabled until Vault is initialized/unsealed and a real `vault_token` is configured. |
| Argo CD module | Import pending | Module is implemented but should remain disabled until the existing Argo CD release is imported into Terraform state. |
| Tempo tracing | Staged disabled | Module is implemented but disabled until a trace emitter (OpenTelemetry SDK/Collector) is configured in workloads. |

---

## Troubleshooting

```bash
# Provider or plugin issues
terraform init -upgrade
rm -rf .terraform && terraform init

# Kubeconfig problems
kubectl config view
kubectl config get-contexts
kubectl config use-context kubernetes-admin@kubernetes

# State drift — refresh without applying
terraform plan -refresh-only

# Manually reconcile an existing resource
terraform import <resource_address> <resource_id>
terraform plan   # verify no unexpected changes
```

---

**See Also:**
- [Terraform Registry — kubernetes provider](https://registry.terraform.io/providers/hashicorp/kubernetes)
- [Terraform Registry — helm provider](https://registry.terraform.io/providers/hashicorp/helm)
- [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- [ingress-nginx](https://github.com/kubernetes/ingress-nginx/tree/main/charts/ingress-nginx)
