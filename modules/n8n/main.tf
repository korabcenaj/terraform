locals {
  webhook_url = trimspace(var.webhook_url) != "" ? trimspace(var.webhook_url) : "https://${var.ingress_host}"
}

resource "kubernetes_namespace" "n8n" {
  metadata {
    name = var.namespace
    labels = merge(var.tags, {
      name                                 = var.namespace
      "pod-security.kubernetes.io/enforce" = "baseline"
    })
  }
}

resource "helm_release" "n8n" {
  name       = var.release_name
  repository = "https://8gears.container-registry.com/chartrepo/library"
  chart      = "n8n"
  version    = var.chart_version
  namespace  = kubernetes_namespace.n8n.metadata[0].name

  # Database: SQLite (single-replica, no external dependency)
  set {
    name  = "config.database.type"
    value = "sqlite"
  }

  # Encryption key for stored credentials
  set_sensitive {
    name  = "secret.n8n.encryption_key"
    value = var.encryption_key
  }

  # Timezone / webhook base URL
  set {
    name  = "config.generic.timezone"
    value = var.timezone
  }

  set {
    name  = "config.n8n.editor_base_url"
    value = local.webhook_url
  }

  set {
    name  = "config.webhook_url"
    value = local.webhook_url
  }

  # Persistence
  set {
    name  = "persistence.enabled"
    value = "true"
  }

  set {
    name  = "persistence.size"
    value = var.storage_size
  }

  set {
    name  = "persistence.storageClass"
    value = var.storage_class
  }

  # Ingress
  set {
    name  = "ingress.enabled"
    value = "true"
  }

  set {
    name  = "ingress.className"
    value = "traefik"
  }

  set {
    name  = "ingress.annotations.cert-manager\\.io/cluster-issuer"
    value = "local-lan-ca"
  }

  dynamic "set" {
    for_each = var.oauth2_proxy_middleware != "" ? [1] : []
    content {
      name  = "ingress.annotations.traefik\\.ingress\\.kubernetes\\.io/router\\.middlewares"
      value = var.oauth2_proxy_middleware
    }
  }

  set {
    name  = "ingress.hosts[0].host"
    value = var.ingress_host
  }

  set {
    name  = "ingress.hosts[0].paths[0].path"
    value = "/"
  }

  set {
    name  = "ingress.hosts[0].paths[0].pathType"
    value = "Prefix"
  }

  set {
    name  = "ingress.tls[0].secretName"
    value = "n8n-tls"
  }

  set {
    name  = "ingress.tls[0].hosts[0]"
    value = var.ingress_host
  }

  # Resources
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
