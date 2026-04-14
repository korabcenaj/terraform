resource "kubernetes_namespace" "tracing" {
  metadata {
    name = var.namespace
    labels = merge(var.tags, {
      name                                 = var.namespace
      "pod-security.kubernetes.io/enforce" = "baseline"
    })
  }
}

resource "helm_release" "tempo" {
  name       = var.release_name
  repository = "https://grafana.github.io/helm-charts"
  chart      = "tempo"
  version    = var.chart_version
  namespace  = kubernetes_namespace.tracing.metadata[0].name

  set {
    name  = "tempo.reportingEnabled"
    value = "false"
  }

  set {
    name  = "persistence.enabled"
    value = "true"
  }

  set {
    name  = "persistence.storageClassName"
    value = var.storage_class
  }

  set {
    name  = "persistence.size"
    value = var.storage_size
  }

  # Enable OTLP and Jaeger receivers so workloads can send traces easily.
  set {
    name  = "tempo.receivers.otlp.protocols.grpc"
    value = "null"
  }

  set {
    name  = "tempo.receivers.otlp.protocols.http"
    value = "null"
  }

  set {
    name  = "tempo.receivers.jaeger.protocols.grpc"
    value = "null"
  }

  wait    = true
  timeout = 300
}