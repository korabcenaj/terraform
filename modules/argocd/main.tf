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

  set {
    name  = "configs.params.server.insecure"
    value = "true"
  }

  dynamic "set_sensitive" {
    for_each = trimspace(var.admin_password_bcrypt) != "" ? [1] : []
    content {
      name  = "configs.secret.argocdServerAdminPassword"
      value = var.admin_password_bcrypt
    }
  }

  wait    = true
  timeout = 600
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