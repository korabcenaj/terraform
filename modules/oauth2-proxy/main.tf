resource "kubernetes_namespace" "oauth2_proxy" {
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

resource "helm_release" "oauth2_proxy" {
  name       = var.release_name
  repository = "https://oauth2-proxy.github.io/manifests"
  chart      = "oauth2-proxy"
  version    = var.chart_version
  namespace  = kubernetes_namespace.oauth2_proxy.metadata[0].name

  set {
    name  = "config.clientID"
    value = var.client_id
  }

  set_sensitive {
    name  = "config.clientSecret"
    value = var.client_secret
  }

  set_sensitive {
    name  = "config.cookieSecret"
    value = var.cookie_secret
  }

  set {
    name  = "extraArgs.provider"
    value = var.oauth2_provider
  }

  set {
    name  = "extraArgs.email-domain"
    value = var.email_domain
  }

  # When used as nginx forward-auth, the proxy itself does not need a backend upstream
  set {
    name  = "extraArgs.upstream"
    value = "file:///dev/null"
  }

  set {
    name  = "extraArgs.skip-provider-button"
    value = "true"
  }

  # Disable the built-in ingress — Terraform manages it below
  set {
    name  = "ingress.enabled"
    value = "false"
  }

  set {
    name  = "service.type"
    value = "ClusterIP"
  }

  wait    = true
  timeout = 300
}

resource "kubernetes_ingress_v1" "oauth2_proxy" {
  metadata {
    name      = "oauth2-proxy"
    namespace = kubernetes_namespace.oauth2_proxy.metadata[0].name
    labels    = var.tags
    annotations = {
      "cert-manager.io/cluster-issuer" = "local-lan-ca"
    }
  }

  spec {
    ingress_class_name = "nginx"

    tls {
      hosts       = [var.ingress_host]
      secret_name = "oauth2-proxy-tls"
    }

    rule {
      host = var.ingress_host
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = var.release_name
              port {
                number = 4180
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.oauth2_proxy]
}
