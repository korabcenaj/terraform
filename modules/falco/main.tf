resource "kubernetes_namespace" "falco" {
  metadata {
    name = "falco"
    labels = merge(var.tags, {
      name                                 = "falco"
      "pod-security.kubernetes.io/enforce" = "privileged"
    })
  }

  lifecycle {
    ignore_changes = [metadata[0].annotations]
  }
}

resource "helm_release" "falco" {
  name       = var.release_name
  repository = "https://falcosecurity.github.io/charts"
  chart      = "falco"
  version    = var.chart_version
  namespace  = kubernetes_namespace.falco.metadata[0].name

  set {
    name  = "tty"
    value = "true"
  }

  wait    = true
  timeout = 300
}
