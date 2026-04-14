resource "kubernetes_namespace" "vault" {
  metadata {
    name = var.namespace
    labels = merge(var.tags, {
      name                                 = var.namespace
      "pod-security.kubernetes.io/enforce" = "restricted"
    })
  }
}

resource "helm_release" "vault" {
  name       = var.release_name
  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"
  version    = var.chart_version
  namespace  = kubernetes_namespace.vault.metadata[0].name

  set {
    name  = "server.dev.enabled"
    value = "false"
  }

  set {
    name  = "server.ha.enabled"
    value = "false"
  }

  set {
    name  = "server.standalone.enabled"
    value = "true"
  }

  set {
    name  = "server.dataStorage.enabled"
    value = "true"
  }

  set {
    name  = "server.dataStorage.storageClass"
    value = var.storage_class
  }

  set {
    name  = "server.dataStorage.size"
    value = var.storage_size
  }

  set {
    name  = "ui.enabled"
    value = "true"
  }

  wait    = true
  timeout = 600
}