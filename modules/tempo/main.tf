locals {
  receivers_values = yamlencode({
    tempo = {
      receivers = {
        otlp = {
          protocols = {
            grpc = {}
            http = {}
          }
        }
        jaeger = {
          protocols = {
            grpc          = {}
            thrift_http   = {}
            thrift_binary = {}
          }
        }
      }
    }
  })
}

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
  values     = [local.receivers_values]

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

  wait    = true
  timeout = 300
}