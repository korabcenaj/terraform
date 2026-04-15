locals {
  base_values = yamlencode({
    configs = {
      params = {
        "server.insecure" = true
      }
    }
    repoServer = {
      livenessProbe = {
        initialDelaySeconds = 20
        timeoutSeconds      = 5
        periodSeconds       = 15
      }
      readinessProbe = {
        initialDelaySeconds = 15
        timeoutSeconds      = 5
        periodSeconds       = 10
      }
    }
  })

  oidc_values = var.oidc_enabled ? yamlencode({
    configs = {
      cm = {
        url = "https://${var.ingress_host}"
        "oidc.config" = yamlencode({
          name                     = var.oidc_name
          issuer                   = var.oidc_issuer_url
          clientID                 = var.oidc_client_id
          clientSecret             = "$argocd-oidc-secret:clientSecret"
          requestedScopes          = var.oidc_scopes
          requestedIDTokenClaims   = { groups = { essential = true } }
          enableUserInfoGroups     = true
          userInfoPath             = "/protocol/openid-connect/userinfo"
          enablePKCEAuthentication = true
          rootCA                   = trimspace(var.oidc_root_ca_pem) != "" ? var.oidc_root_ca_pem : null
        })
      }
    }
  }) : ""
}

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.namespace
    labels = merge(var.tags, {
      name                                 = var.namespace
      "pod-security.kubernetes.io/enforce" = "baseline"
    })
  }

  lifecycle {
    ignore_changes = [metadata[0].annotations]
  }
}

resource "kubernetes_secret_v1" "oidc_client_secret" {
  count = var.oidc_enabled ? 1 : 0

  metadata {
    name      = "argocd-oidc-secret"
    namespace = kubernetes_namespace.argocd.metadata[0].name
    labels = merge(var.tags, {
      "app.kubernetes.io/part-of" = "argocd"
    })
  }

  type = "Opaque"

  data = {
    clientSecret = var.oidc_client_secret
  }
}

resource "helm_release" "argocd" {
  name       = var.release_name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.chart_version
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  set {
    name  = "server.service.type"
    value = "ClusterIP"
  }

  dynamic "set_sensitive" {
    for_each = trimspace(var.admin_password_bcrypt) != "" ? [1] : []
    content {
      name  = "configs.secret.argocdServerAdminPassword"
      value = var.admin_password_bcrypt
    }
  }

  values = compact([local.base_values, local.oidc_values])

  wait    = true
  timeout = 600

  depends_on = [kubernetes_secret_v1.oidc_client_secret]
}

resource "kubernetes_ingress_v1" "argocd_server" {
  metadata {
    name      = "argocd-server"
    namespace = kubernetes_namespace.argocd.metadata[0].name
    labels    = var.tags
    annotations = {
      "cert-manager.io/cluster-issuer"               = "local-lan-ca"
      "nginx.ingress.kubernetes.io/ssl-passthrough"  = "false"
      "nginx.ingress.kubernetes.io/backend-protocol" = "HTTP"
    }
  }

  spec {
    ingress_class_name = "nginx"

    tls {
      hosts       = [var.ingress_host]
      secret_name = "argocd-tls"
    }

    rule {
      host = var.ingress_host
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "${var.release_name}-server"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.argocd]
}