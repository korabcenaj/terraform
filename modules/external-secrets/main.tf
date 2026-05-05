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

# ---------------------------------------------------------------------------
# ClusterSecretStore — token auth (simple bootstrap, no Vault init required)
# ---------------------------------------------------------------------------

resource "kubernetes_secret_v1" "vault_token" {
  count = var.create_vault_cluster_secret_store && var.vault_auth_method == "token" ? 1 : 0

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
          auth = var.vault_auth_method == "kubernetes" ? {
            kubernetes = {
              mountPath = var.vault_kubernetes_mount_path
              role      = var.vault_kubernetes_role
              serviceAccountRef = {
                name      = kubernetes_service_account_v1.eso_vault_auth[0].metadata[0].name
                namespace = kubernetes_namespace.external_secrets.metadata[0].name
              }
            }
            tokenSecretRef = null
            } : {
            kubernetes = null
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

  depends_on = [
    helm_release.external_secrets,
    kubernetes_secret_v1.vault_token,
    kubernetes_service_account_v1.eso_vault_auth,
  ]
}

# ---------------------------------------------------------------------------
# Kubernetes auth — ServiceAccount for pod-to-Vault authentication
#
# Vault must be pre-configured with:
#   vault auth enable kubernetes
#   vault write auth/kubernetes/config \
#     kubernetes_host="https://kubernetes.default.svc"
#   vault write auth/kubernetes/role/<vault_kubernetes_role> \
#     bound_service_account_names=eso-vault-auth \
#     bound_service_account_namespaces=external-secrets \
#     policies=<your-policy> ttl=1h
# ---------------------------------------------------------------------------

resource "kubernetes_service_account_v1" "eso_vault_auth" {
  count = var.create_vault_cluster_secret_store && var.vault_auth_method == "kubernetes" ? 1 : 0

  metadata {
    name      = "eso-vault-auth"
    namespace = kubernetes_namespace.external_secrets.metadata[0].name
    labels    = var.tags
    annotations = {
      "vault.hashicorp.com/role" = var.vault_kubernetes_role
    }
  }

  automount_service_account_token = true

  depends_on = [helm_release.external_secrets]
}