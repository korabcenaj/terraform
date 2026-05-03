resource "kubernetes_namespace" "harbor" {
  metadata {
    name = var.namespace
    labels = merge(var.tags, {
      name                                 = var.namespace
      "pod-security.kubernetes.io/enforce" = "privileged"
    })
  }
}

resource "helm_release" "harbor" {
  name       = var.release_name
  repository = "https://helm.goharbor.io"
  chart      = "harbor"
  version    = var.chart_version
  namespace  = kubernetes_namespace.harbor.metadata[0].name

  wait    = true
  timeout = 600

  set {
    name  = "externalURL"
    value = var.external_url
  }

  set {
    name  = "harborAdminPassword"
    value = var.admin_password
    type  = "string"
  }

  set {
    name  = "expose.type"
    value = var.expose_type
  }

  set {
    name  = "expose.ingress.hosts.core"
    value = var.ingress_host
  }

  set {
    name  = "expose.ingress.className"
    value = var.ingress_class_name
  }

  set {
    name  = "expose.tls.enabled"
    value = tostring(var.tls_enabled)
  }

  # Persistent storage for registry data
  set {
    name  = "persistence.enabled"
    value = "true"
  }

  set {
    name  = "persistence.persistentVolumeClaim.registry.storageClass"
    value = var.storage_class
  }

  set {
    name  = "persistence.persistentVolumeClaim.registry.size"
    value = var.registry_storage_size
  }

  set {
    name  = "persistence.persistentVolumeClaim.database.storageClass"
    value = var.storage_class
  }

  set {
    name  = "persistence.persistentVolumeClaim.redis.storageClass"
    value = var.storage_class
  }

  # Disable internal Trivy if handled externally (e.g., via Falco)
  set {
    name  = "trivy.enabled"
    value = tostring(var.enable_trivy)
  }

  dynamic "set" {
    for_each = var.extra_values
    content {
      name  = set.key
      value = set.value
    }
  }
}
