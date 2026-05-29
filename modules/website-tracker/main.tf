# Website Tracker Operator - managed via Helm (custom chart from local Harbor registry)

resource "kubernetes_namespace" "website_tracker" {
  metadata {
    name = "website-tracker-system"
    labels = merge(var.tags, {
      name = "website-tracker-system"
    })
  }

  lifecycle {
    ignore_changes = [metadata[0].annotations]
  }
}

resource "helm_release" "website_tracker" {
  name      = var.release_name
  chart     = var.chart_path
  version   = var.chart_version
  namespace = kubernetes_namespace.website_tracker.metadata[0].name

  set {
    name  = "crds.create"
    value = "false"
  }

  set {
    name  = "manager.image.registry"
    value = var.image_registry
  }

  set {
    name  = "manager.image.repository"
    value = var.image_repository
  }

  set {
    name  = "manager.image.tag"
    value = var.image_tag
  }

  set {
    name  = "manager.image.pullPolicy"
    value = "Always"
  }

  set {
    name  = "manager.replicaCount"
    value = "1"
  }

  set {
    name  = "manager.imagePullSecrets[0].name"
    value = var.image_pull_secret
  }

  set {
    name  = "manager.leaderElection.enabled"
    value = "false"
  }

  set {
    name  = "metrics.enabled"
    value = "true"
  }

  set {
    name  = "metrics.port"
    value = "8080"
  }

  set {
    name  = "metrics.service.enabled"
    value = "true"
  }

  set {
    name  = "metrics.service.type"
    value = "ClusterIP"
  }

  set {
    name  = "metrics.serviceMonitor.enabled"
    value = "true"
  }

  set {
    name  = "metrics.serviceMonitor.interval"
    value = "30s"
  }

  set {
    name  = "metrics.serviceMonitor.labels.release"
    value = "monitor"
  }

  set {
    name  = "rbac.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "website-tracker-controller-manager"
  }

  set {
    name  = "webhooks.enabled"
    value = "false"
  }

  wait    = true
  timeout = 300
}
