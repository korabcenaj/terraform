resource "kubernetes_namespace" "gitea" {
  metadata {
    name = "git"
    labels = merge(var.tags, {
      name = "git"
    })
  }

  lifecycle {
    ignore_changes = [metadata[0].annotations]
  }
}

resource "helm_release" "gitea" {
  name       = var.release_name
  repository = "https://dl.gitea.com/charts"
  chart      = "gitea"
  version    = var.chart_version
  namespace  = kubernetes_namespace.gitea.metadata[0].name

  set {
    name  = "gitea.admin.username"
    value = var.admin_username
  }

  set {
    name  = "gitea.admin.password"
    value = var.admin_password
  }

  set {
    name  = "gitea.admin.email"
    value = var.admin_email
  }

  set {
    name  = "gitea.config.server.DOMAIN"
    value = var.ingress_host
  }

  set {
    name  = "gitea.config.server.ROOT_URL"
    value = "https://${var.ingress_host}/"
  }

  set {
    name  = "gitea.config.server.SSH_DOMAIN"
    value = var.ingress_host
  }

  set {
    name  = "image.tag"
    value = var.image_tag
  }

  set {
    name  = "ingress.enabled"
    value = "true"
  }

  set {
    name  = "ingress.className"
    value = var.ingress_class_name
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
    name  = "ingress.tls[0].hosts[0]"
    value = var.ingress_host
  }

  set {
    name  = "ingress.tls[0].secretName"
    value = "${replace(var.ingress_host, ".", "-")}-tls"
  }

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

  set {
    name  = "postgresql.enabled"
    value = "true"
  }

  set {
    name  = "postgresql.auth.username"
    value = "gitea"
  }

  set {
    name  = "postgresql.auth.password"
    value = var.postgresql_password
  }

  set {
    name  = "postgresql.auth.database"
    value = "gitea"
  }

  set {
    name  = "postgresql-ha.enabled"
    value = "false"
  }

  set {
    name  = "redis-cluster.enabled"
    value = "false"
  }

  set {
    name  = "valkey-cluster.enabled"
    value = "false"
  }

  wait    = true
  timeout = 600
}
