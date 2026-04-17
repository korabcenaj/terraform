resource "kubernetes_namespace" "argo_rollouts" {
  metadata {
    name = var.namespace
    labels = merge(var.tags, {
      name                                 = var.namespace
      "pod-security.kubernetes.io/enforce" = "baseline"
    })
  }

  lifecycle {
    ignore_changes = [metadata[0].annotations]
  }
}

resource "helm_release" "argo_rollouts" {
  name       = var.release_name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-rollouts"
  version    = var.chart_version
  namespace  = kubernetes_namespace.argo_rollouts.metadata[0].name

  set {
    name  = "installCRDs"
    value = "true"
  }

  set {
    name  = "dashboard.enabled"
    value = tostring(var.dashboard_enabled)
  }

  wait    = true
  timeout = 600
}
