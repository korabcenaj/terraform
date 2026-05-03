resource "helm_release" "pushgateway" {
  name       = var.release_name
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-pushgateway"
  version    = var.chart_version
  namespace  = var.namespace

  wait    = true
  timeout = 300

  # Service monitor for Prometheus scraping
  set {
    name  = "serviceMonitor.enabled"
    value = tostring(var.enable_service_monitor)
  }

  set {
    name  = "serviceMonitor.namespace"
    value = var.namespace
  }

  # Persistence for push data survival across restarts
  set {
    name  = "persistentVolume.enabled"
    value = tostring(var.persistence_enabled)
  }

  dynamic "set" {
    for_each = var.extra_values
    content {
      name  = set.key
      value = set.value
    }
  }
}
