# Longhorn — distributed block storage for Kubernetes.
# Deploys into longhorn-system namespace.

resource "kubernetes_namespace" "longhorn" {
  metadata {
    name = var.namespace
    labels = merge(var.tags, {
      name                                 = var.namespace
      "pod-security.kubernetes.io/enforce" = "privileged"
    })
  }
}

resource "helm_release" "longhorn" {
  name       = var.release_name
  repository = "https://charts.longhorn.io"
  chart      = "longhorn"
  version    = var.chart_version
  namespace  = kubernetes_namespace.longhorn.metadata[0].name
  timeout    = var.timeout

  set {
    name  = "defaultSettings.defaultDataPath"
    value = var.default_data_path
  }

  set {
    name  = "persistence.defaultClass"
    value = var.persistence_default_class
  }

  set {
    name  = "persistence.defaultClassReplicaCount"
    value = var.default_replica_count
  }
}
