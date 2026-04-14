resource "kubernetes_namespace" "external_secrets" {
  metadata {
    name = var.namespace
    labels = merge(var.tags, {
      name                                 = var.namespace
      "pod-security.kubernetes.io/enforce" = "restricted"
    })
  }
}

resource "helm_release" "external_secrets" {
  name       = var.release_name
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  version    = var.chart_version
  namespace  = kubernetes_namespace.external_secrets.metadata[0].name

  set {
    name  = "installCRDs"
    value = "true"
  }

  wait    = true
  timeout = 300
}

resource "kubernetes_secret_v1" "vault_token" {
  count = var.create_vault_cluster_secret_store ? 1 : 0

  metadata {
    name      = "vault-token"
    namespace = kubernetes_namespace.external_secrets.metadata[0].name
    labels    = var.tags
  }

  type = "Opaque"

  data = {
    token = var.vault_token
  }

  depends_on = [helm_release.external_secrets]
}

resource "kubernetes_manifest" "vault_cluster_secret_store" {
  count = var.create_vault_cluster_secret_store ? 1 : 0

  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ClusterSecretStore"
    metadata = {
      name   = var.cluster_secret_store_name
      labels = var.tags
    }
    spec = {
      provider = {
        vault = {
          server  = var.vault_server
          path    = var.vault_kv_path
          version = "v2"
          auth = {
            tokenSecretRef = {
              name      = kubernetes_secret_v1.vault_token[0].metadata[0].name
              key       = "token"
              namespace = kubernetes_namespace.external_secrets.metadata[0].name
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.external_secrets, kubernetes_secret_v1.vault_token]
}