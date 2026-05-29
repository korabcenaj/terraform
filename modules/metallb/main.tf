resource "kubernetes_namespace" "metallb" {
  metadata {
    name = "metallb-system"
    labels = merge(var.tags, {
      name                                 = "metallb-system"
      "pod-security.kubernetes.io/enforce" = "privileged"
    })
  }

  lifecycle {
    ignore_changes = [metadata[0].annotations]
  }
}

resource "helm_release" "metallb" {
  name       = var.release_name
  repository = "https://metallb.github.io/metallb"
  chart      = "metallb"
  version    = var.chart_version
  namespace  = kubernetes_namespace.metallb.metadata[0].name

  wait    = true
  timeout = 300
}
