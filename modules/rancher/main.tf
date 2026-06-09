# Rancher — namespace only
# The Helm release is managed externally (installed via Helm CLI).
# Rancher chart v2.14.1 requires kubeVersion < 1.36.0 but cluster runs v1.36.1.
# Terraform manages only the namespace to avoid kubeVersion incompatibility.

resource "kubernetes_namespace" "cattle_system" {
  metadata {
    name = "cattle-system"
    labels = merge(var.tags, {
      name                                 = "cattle-system"
      "pod-security.kubernetes.io/enforce" = "privileged"
    })
  }

  lifecycle {
    ignore_changes = [metadata[0].annotations]
  }
}
