resource "kubernetes_namespace" "argocd" {
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

resource "helm_release" "argocd" {
  name       = var.release_name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.chart_version
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  set {
    name  = "server.service.type"
    value = "ClusterIP"
  }

  set {
    name  = "configs.params.server.insecure"
    value = "true"
  }

  dynamic "set_sensitive" {
    for_each = trimspace(var.admin_password_bcrypt) != "" ? [1] : []
    content {
      name  = "configs.secret.argocdServerAdminPassword"
      value = var.admin_password_bcrypt
    }
  }

  wait    = true
  timeout = 600
}