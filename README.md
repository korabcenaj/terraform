# Terraform Docker-Apps Infrastructure as Code

## Quick Start

### 1. Prerequisites

```bash
# Install Terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform

# Verify installation
terraform --version

# Ensure kubectl access
kubectl cluster-info
kubectl get nodes
```

### 2. Initialize Terraform

```bash
cd /home/mena/docker-apps/terraform

# Initialize Terraform (downloads providers)
terraform init

# Verify configuration
terraform validate
terraform fmt -recursive
```

### 3. Plan Deployment

```bash
# Review what will be created/changed
terraform plan -out=tfplan

# Save plan for reproducibility
terraform show tfplan
```

### 4. Apply Configuration

```bash
# Create all resources
terraform apply tfplan

# Or directly (requires confirmation)
terraform apply

# View outputs
terraform output
```

### 5. Verify Deployment

```bash
# Check Kubernetes resources
kubectl get namespaces
kubectl get deployments -A
kubectl get services -A

# Portfolio service
kubectl port-forward -n portfolio svc/portfolio-web 8080:80 &
curl http://localhost:8080

# Jellyfin service
kubectl port-forward -n jellyfin svc/jellyfin 8096:8096 &
# Access at http://localhost:8096
```

---

## Configuration

### Common Variables

Edit `terraform.tfvars` to customize:

```hcl
# Enable/disable specific applications
enable_portfolio    = true
enable_jellyfin     = true
enable_qbittorrent  = true

# Cluster settings
cluster_name       = "home-lab"
environment        = "production"
kubeconfig_path    = "~/.kube/config"

# Resource allocation
default_cpu_request    = "100m"
default_memory_request = "128Mi"
default_cpu_limit      = "250m"
default_memory_limit   = "256Mi"
```

### Scale Applications

```bash
# Increase replicas
terraform apply -var="portfolio_replicas=2"

# Or edit terraform.tfvars and apply
```

---

## Project Structure

```
terraform/
├── provider.tf              # Kubernetes provider config
├── variables.tf             # Input variables
├── main.tf                  # Main resources & modules
├── outputs.tf               # Output values
├── terraform.tfvars         # Variable values (customize this)
├── terraform.tfstate        # Current state (auto-generated, don't edit)
│
└── modules/                 # Reusable modules
    ├── portfolio/           # Portfolio web application
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── jellyfin/            # Jellyfin media server
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── qbittorrent/         # qBittorrent torrent client
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── monitoring/          # Monitoring stack reference
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    └── networking/          # Network policies
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## Common Commands

```bash
# Initialize (first time only)
terraform init

# Validate configuration
terraform validate

# Format code
terraform fmt -recursive

# Plan changes (dry-run)
terraform plan

# Apply changes
terraform apply

# Destroy resources
terraform destroy

# View current state
terraform state list

# Inspect specific resource
terraform state show kubernetes_deployment.portfolio

# Get output values
terraform output
terraform output -json
```

## Metrics Server

`metrics-server` is now managed by Terraform and enabled by default.

```bash
# Verify deployment
kubectl get deploy -n kube-system metrics-server

# Verify live metrics
kubectl top nodes
kubectl top pods -A
```

Disable if needed:

```bash
terraform apply -var="enable_metrics_server=false"
```

## CI (Terraform Checks)

A default CI workflow is included at [.github/workflows/terraform-ci.yml](.github/workflows/terraform-ci.yml).

It always runs:

```bash
terraform init -backend=false
terraform fmt -check -recursive
terraform validate
tflint --recursive
tfsec
kubeconform -strict -ignore-missing-schemas <root-manifests>
```

A separate manual plan workflow is included at [.github/workflows/terraform-plan.yml](.github/workflows/terraform-plan.yml).

It requires the GitHub secret `KUBECONFIG_B64`, set to a base64-encoded kubeconfig for your cluster.

For this repository, the manual plan workflow is intended to run on a self-hosted Linux runner inside the homelab.
If the kubeconfig server is something like `https://k8s-master.local:6443`, a GitHub-hosted runner will usually fail unless that name is resolvable and routable from the runner.

Create that secret from a local kubeconfig with:

```bash
base64 ~/.kube/config | tr -d '\n'
```

Use the output as the value for the repository secret `KUBECONFIG_B64`.

Use a dedicated automation kubeconfig if needed. Its `server` endpoint must be reachable from the runner that executes the workflow.

Recommended runner shape:

- GitHub self-hosted runner
- Linux host on the same LAN as the cluster
- `terraform`, `kubectl`, and network access to the Kubernetes API
- runner labels including `self-hosted`, `linux`, `homelab`, and `terraform`
- local DNS resolution for the Kubernetes API server hostname (e.g., `k8s-master.local`)

If the kubeconfig server uses a private/local hostname like `https://k8s-master.local:6443`, ensure the runner host can resolve it.

For this setup, add an entry to `/etc/hosts`:

```bash
echo "192.168.1.15 k8s-master.local" | sudo tee -a /etc/hosts
```

Adjust the IP and hostname to match your cluster's actual API server.

High-level setup:

```bash
# 1. In GitHub, open Settings -> Actions -> Runners and generate a repository runner token.
# 2. On the chosen homelab host, run:

export GH_RUNNER_TOKEN=<runner-registration-token>
./scripts/setup-github-runner.sh install --service
```

Once the runner is registered and online, the manual workflow can execute cluster-backed plans without exposing the API publicly.

Useful runner lifecycle commands:

```bash
./scripts/setup-github-runner.sh status
./scripts/setup-github-runner.sh stop
./scripts/setup-github-runner.sh start
./scripts/setup-github-runner.sh remove --token <runner-removal-token>
```

Generate the `KUBECONFIG_B64` secret value with:

```bash
./scripts/print-kubeconfig-b64.sh
```

Or point it at a dedicated automation kubeconfig:

```bash
./scripts/print-kubeconfig-b64.sh /path/to/automation-kubeconfig
```

If `gh` is installed and authenticated, update the GitHub repository secret directly with:

```bash
./scripts/set-github-secret.sh --name KUBECONFIG_B64
```

Install `gh` on Ubuntu/Debian with:

```bash
./scripts/install-gh.sh
gh auth login
./scripts/set-github-secret.sh --name KUBECONFIG_B64
```

If `sudo` prompts for a password on this host, run the installer directly in an interactive shell and complete the prompt there.

The manual plan workflow refuses to run unless one of these is true:

- `terraform.tfstate` is available in the workflow checkout
- a real Terraform backend is enabled in `provider.tf`

This prevents misleading plans generated from an empty state on GitHub-hosted runners.

## Backup and Restore Runbook

Backup script: [scripts/backup.sh](scripts/backup.sh)
Restore script: [scripts/restore.sh](scripts/restore.sh)

What gets backed up:

- Terraform state files
- cert-manager root CA secret (`local-lan-ca-secret`)
- Pi-hole configuration (`/etc/pihole`, `/etc/dnsmasq.d`)

Create backup:

```bash
./scripts/backup.sh
```

Restore backup:

```bash
./scripts/restore.sh --dry-run backups/<timestamp>
./scripts/restore.sh --yes backups/<timestamp>
```

Example:

```bash
./scripts/restore.sh --dry-run backups/20260411-120000
./scripts/restore.sh --yes backups/20260411-120000
```

Note: Terraform state restore is intentionally manual to avoid accidental state overwrite.

## State Management

### Important: Backup State

```bash
# Terraform creates terraform.tfstate (contains all resource info)
# BACKUP THIS FILE!

cp terraform/terraform.tfstate terraform/terraform.tfstate.backup

# For safety, commit to Git:
# (after adding to .gitignore and using secrets management)
```

### Remote State (Recommended for Teams)

This repository now includes a safe backend scaffold:

```bash
cp backend.tf.example backend.tf
cp backend.kubernetes.hcl.example backend.kubernetes.hcl
# Edit backend.kubernetes.hcl with your real values
terraform init -migrate-state -backend-config=backend.kubernetes.hcl
```

Notes:

- `backend.tf` is intentionally not committed by default.
- `backend.kubernetes.hcl` is ignored by git.
- Manual plan CI checks for either local `terraform.tfstate` or an enabled backend block.

```hcl
# Example backend.tf content:
terraform {
  backend "kubernetes" {}
}
```

Optional paid/cloud alternative:

- Keep `backend.tf.example` and use `backend.s3.hcl.example` (S3 + DynamoDB locking).

## Troubleshooting

### Provider Issues

```bash
# Reinitialize providers
terraform init -upgrade

# Clear cached providers
rm -rf .terraform
terraform init
```

### Kubeconfig Issues

```bash
# Verify kubeconfig
kubectl config view

# Use specific context
terraform apply -var="kubeconfig_context=kubernetes-admin@kubernetes"
```

### State Conflicts

```bash
# Refresh state
terraform refresh

# Manually import resource
terraform import kubernetes_deployment.portfolio \
  portfolio/portfolio-web
```

## Best Practices

✅ **Always plan before apply**
```bash
terraform plan -out=tfplan
terraform apply tfplan
```

✅ **Use workspaces for environments**
```bash
terraform workspace new staging
terraform apply
terraform workspace select default
```

✅ **Version control**
```bash
git add terraform/
git commit -m "Update cluster configuration"

# But exclude state files
echo "terraform.tfstate*" >> .gitignore
```

✅ **Document changes**
```bash
terraform apply -auto-approve \
  -var="portfolio_replicas=2" \
  -lock-timeout=0s
```

✅ **Destroy safely**
```bash
# Always verify before destroying
terraform plan -destroy
terraform destroy -auto-approve
```

## Advanced: Adding New Applications

### 1. Create Module

```bash
mkdir terraform/modules/myapp
cd terraform/modules/myapp

# Create: variables.tf, main.tf, outputs.tf
```

### 2. Reference in main.tf

```hcl
module "myapp" {
  source    = "./modules/myapp"
  namespace = kubernetes_namespace.myapp[0].metadata[0].name
  
  depends_on = [kubernetes_namespace.myapp]
}
```

### 3. Add Variable

```hcl
variable "enable_myapp" {
  description = "Enable my application"
  type        = bool
  default     = false
}
```

### 4. Deploy

```bash
terraform apply -var="enable_myapp=true"
```

---

## Migration from Manual kubectl

If you deployed manually with `kubectl apply`, migrate to Terraform:

```bash
# 1. Import existing resources
terraform import kubernetes_deployment.portfolio \
  portfolio/portfolio-web

# 2. Update module code to match
terraform plan

# 3. Apply Terraform
terraform apply
```

## Monitoring Changes

```bash
# Watch Terraform apply
terraform apply | tee apply.log

# Track Kubernetes changes
kubectl get events -A --watch

# Monitor pod rollouts
kubectl rollout status deployment/portfolio-web -n portfolio
```

---

**See Also:**
- [README.md](../README.md) - Cluster overview
- [IMPROVEMENTS.md](../IMPROVEMENTS.md) - Improvement roadmap
- [Terraform Docs](https://registry.terraform.io/providers/hashicorp/kubernetes)
