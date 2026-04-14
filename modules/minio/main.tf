resource "kubernetes_namespace" "minio" {
  metadata {
    name = var.namespace
    labels = merge(var.tags, {
      name                                 = var.namespace
      "pod-security.kubernetes.io/enforce" = "baseline"
    })
  }
}

resource "helm_release" "minio" {
  name       = var.release_name
  repository = "https://charts.min.io/"
  chart      = "minio"
  version    = var.chart_version
  namespace  = kubernetes_namespace.minio.metadata[0].name

  set {
    name  = "mode"
    value = "standalone"
  }

  set {
    name  = "rootUser"
    value = var.root_user
  }

  set_sensitive {
    name  = "rootPassword"
    value = var.root_password
  }

  set {
    name  = "persistence.enabled"
    value = "true"
  }

  set {
    name  = "persistence.storageClass"
    value = var.storage_class
  }

  set {
    name  = "persistence.size"
    value = var.storage_size
  }

  set {
    name  = "resources.requests.cpu"
    value = "100m"
  }

  set {
    name  = "resources.requests.memory"
    value = "256Mi"
  }

  set {
    name  = "resources.limits.cpu"
    value = "500m"
  }

  set {
    name  = "resources.limits.memory"
    value = "512Mi"
  }

  wait    = true
  timeout = 300
}