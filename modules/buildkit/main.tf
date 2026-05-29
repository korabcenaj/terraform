# BuildKit - managed by Argo CD, this creates the namespace + RBAC baseline
# The actual deployment is managed via Argo CD Application

resource "kubernetes_namespace" "buildkit" {
  metadata {
    name = "buildkit"
    labels = merge(var.tags, {
      name                                 = "buildkit"
      "pod-security.kubernetes.io/enforce" = "privileged"
    })
  }

  lifecycle {
    ignore_changes = [metadata[0].annotations]
  }
}
