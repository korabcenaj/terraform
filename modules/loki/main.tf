resource "kubernetes_namespace" "logging" {
  metadata {
    name = var.namespace
    labels = merge(var.tags, {
      name                                 = var.namespace
      "pod-security.kubernetes.io/enforce" = "baseline"
    })
  }
}

resource "helm_release" "loki" {
  name       = var.release_name
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki-stack"
  version    = var.chart_version
  namespace  = kubernetes_namespace.logging.metadata[0].name

  # Persist log data across pod restarts.
  set {
    name  = "loki.persistence.enabled"
    value = "true"
  }

  set {
    name  = "loki.persistence.storageClassName"
    value = var.loki_storage_class
  }

  set {
    name  = "loki.persistence.size"
    value = var.loki_storage_size
  }

  # Promtail DaemonSet ships node and pod logs to Loki.
  set {
    name  = "promtail.enabled"
    value = "true"
  }

  # Grafana is already provided by kube-prometheus-stack.
  set {
    name  = "grafana.enabled"
    value = "false"
  }

  wait    = true
  timeout = 300
}