# ---------------------------------------------------------------------------
# AWX — Ansible Automation Platform (upstream)
#
# Deploys the AWX Operator via Helm, then creates an AWX instance custom
# resource for a fully functional Ansible controller with web UI, API, and
# job scheduling in Kubernetes.
# ---------------------------------------------------------------------------

locals {
  admin_password_secret_name = "${var.awx_instance_name}-admin-password"
}

# ---- Namespace ----
resource "kubernetes_namespace" "awx" {
  metadata {
    name = var.namespace
    labels = merge(var.tags, {
      name                                 = var.namespace
      "pod-security.kubernetes.io/enforce" = "privileged"
      "pod-security.kubernetes.io/audit"   = "restricted"
      "pod-security.kubernetes.io/warn"    = "restricted"
    })
  }
  lifecycle {
    ignore_changes = [metadata[0].annotations]
  }
}

# ---- AWX Operator (kustomize via kubectl) ----
# The AWX Operator is deployed via kustomize from the GitHub repo.
# This is the official install method per the AWX Operator documentation.
locals {
  operator_kustomize_url = "github.com/ansible/awx-operator/config/default?ref=${var.operator_chart_version}"
}

resource "null_resource" "awx_operator" {
  triggers = {
    kustomize_url = local.operator_kustomize_url
    version       = var.operator_chart_version
    namespace_uid = kubernetes_namespace.awx.metadata[0].uid
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail
      # Create Kyverno PolicyException so the operator can deploy (needs hostIPC, root user, :latest tag)
      # Only if Kyverno CRDs are installed; ignore error otherwise
      if kubectl get crd policyexceptions.kyverno.io >/dev/null 2>&1; then
        kubectl apply -f - <<'EOF'
apiVersion: kyverno.io/v2
kind: PolicyException
metadata:
  name: awx-operator
  namespace: ${kubernetes_namespace.awx.metadata[0].name}
spec:
  exceptions:
  - policyName: disallow-host-namespace-sharing
    ruleNames: [autogen-disallow-host-pid-ipc]
  - policyName: disallow-root-user
    ruleNames: [autogen-check-runasnonroot]
  - policyName: restrict-image-tags
    ruleNames: [autogen-block-latest-tag]
  - policyName: disallow-privileged-containers
    ruleNames: [autogen-disallow-privileged-containers]
  match:
    any:
    - resources:
        namespaces: [${kubernetes_namespace.awx.metadata[0].name}]
EOF
      fi

      kubectl apply -k '${local.operator_kustomize_url}' \
        --server-side \
        --field-manager=terraform-awx-operator \
        --force-conflicts
      kubectl rollout status deployment/awx-operator-controller-manager \
        -n ${kubernetes_namespace.awx.metadata[0].name} \
        --timeout=600s || true
    EOT
    interpreter = ["bash", "-c"]
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      set -euo pipefail
      kubectl delete -k '${self.triggers.kustomize_url}' --ignore-not-found || true
    EOT
    interpreter = ["bash", "-c"]
  }
}

# ---- AWX Instance (CR) ----
# The AWX Operator watches for AWX custom resources and provisions
# the full stack: web, task, Redis, PostgreSQL.
resource "kubernetes_manifest" "awx_instance" {
  depends_on = [null_resource.awx_operator]

  manifest = {
    apiVersion = "awx.ansible.com/v1beta1"
    kind       = "AWX"
    metadata = {
      name      = var.awx_instance_name
      namespace = kubernetes_namespace.awx.metadata[0].name
      labels    = var.tags
    }
    spec = {
      admin_user           = var.admin_user
      admin_password_secret = local.admin_password_secret_name
      admin_email          = var.admin_email
      image_version        = var.awx_image_version

      ingress_type  = "ingress"
      ingress_class_name = var.ingress_class_name
      hostname      = var.ingress_host
      ingress_tls_secret = "${var.awx_instance_name}-tls"

      web_replicas  = var.web_replicas
      task_replicas = var.task_replicas

      # Resource limits — prevent AWX from starving the node
      web_resource_requirements = {
        requests = {
          cpu    = "150m"
          memory = "512Mi"
        }
        limits = {
          cpu    = "500m"
          memory = "1Gi"
        }
      }
      task_resource_requirements = {
        requests = {
          cpu    = "100m"
          memory = "256Mi"
        }
        limits = {
          cpu    = "500m"
          memory = "1Gi"
        }
      }

      postgres_configuration_secret = "${var.awx_instance_name}-postgres-configuration"

      # Let the operator create a self-signed cert or use cert-manager
      # for the ingress TLS.  The operator will use the secret named in
      # ingress_tls_secret if it exists, otherwise create one.
    }
  }

  timeouts {
    create = "15m"
    update = "10m"
    delete = "5m"
  }
}

# ---- Admin password secret (only if user supplies one) ----
resource "kubernetes_secret_v1" "admin_password" {
  count = trimspace(var.admin_password) != "" ? 1 : 0

  metadata {
    name      = local.admin_password_secret_name
    namespace = kubernetes_namespace.awx.metadata[0].name
    labels    = var.tags
  }

  data = {
    password = var.admin_password
  }

  type = "Opaque"
}

# ---- PostgreSQL configuration secret ----
resource "kubernetes_secret_v1" "postgres_configuration" {
  metadata {
    name      = "${var.awx_instance_name}-postgres-configuration"
    namespace = kubernetes_namespace.awx.metadata[0].name
    labels    = var.tags
  }

  data = {
    host     = "${var.awx_instance_name}-postgres-15"
    port     = "5432"
    database = var.awx_instance_name
    username = var.awx_instance_name
    password = "" # Operator manages Postgres internally; leave blank for auto-generation
    type     = "managed"
  }

  type = "Opaque"
}
