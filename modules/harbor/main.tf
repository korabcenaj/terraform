resource "kubernetes_namespace" "harbor" {
  metadata {
    name = "harbor"
    labels = merge(var.tags, {
      name = "harbor"
    })
  }

  lifecycle {
    ignore_changes = [metadata[0].annotations]
  }
}

resource "helm_release" "harbor" {
  name       = var.release_name
  repository = "https://helm.goharbor.io"
  chart      = "harbor"
  version    = var.chart_version
  namespace  = kubernetes_namespace.harbor.metadata[0].name

  set {
    name  = "expose.type"
    value = "ingress"
  }

  set {
    name  = "expose.ingress.className"
    value = var.ingress_class_name
  }

  set {
    name  = "expose.ingress.hosts.core"
    value = var.ingress_host
  }

  set {
    name  = "expose.tls.certSource"
    value = "secret"
  }

  set {
    name  = "expose.tls.secret.secretName"
    value = "harbor-tls"
  }

  set {
    name  = "expose.tls.enabled"
    value = "false"
  }

  set {
    name  = "externalURL"
    value = "https://${var.ingress_host}"
  }

  set {
    name  = "harborAdminPassword"
    value = var.admin_password
  }

  set {
    name  = "persistence.enabled"
    value = "true"
  }

  set {
    name  = "persistence.storageClass"
    value = var.storage_class
  }

  wait    = true
  timeout = 600
}
