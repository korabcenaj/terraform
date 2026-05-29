resource "kubernetes_namespace" "keda" {
  metadata {
    name = "keda"
    labels = merge(var.tags, {
      name = "keda"
    })
  }

  lifecycle {
    ignore_changes = [metadata[0].annotations]
  }
}

resource "helm_release" "keda" {
  name       = var.release_name
  repository = "https://kedacore.github.io/charts"
  chart      = "keda"
  version    = var.chart_version
  namespace  = kubernetes_namespace.keda.metadata[0].name

  wait    = true
  timeout = 300
}
