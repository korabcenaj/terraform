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

resource "helm_release" "rancher" {
  name       = var.release_name
  repository = "https://releases.rancher.com/server-charts/stable"
  chart      = "rancher"
  version    = var.chart_version
  namespace  = kubernetes_namespace.cattle_system.metadata[0].name

  set {
    name  = "hostname"
    value = var.hostname
  }

  set {
    name  = "replicas"
    value = tostring(var.replicas)
  }

  set {
    name  = "ingress.tls.source"
    value = var.ingress_tls_source
  }

  dynamic "set" {
    for_each = var.bootstrap_password != "" ? [1] : []
    content {
      name  = "bootstrapPassword"
      value = var.bootstrap_password
    }
  }

  wait    = true
  timeout = 600
}
