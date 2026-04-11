resource "kubernetes_config_map" "portfolio_html" {
  metadata {
    name      = "portfolio-html"
    namespace = var.namespace
    labels = merge(
      var.tags,
      {
        app = "portfolio"
      }
    )
  }

  data = {
    "index.html" = file("${path.module}/../../portfolio-container/portfolio.html")
  }
}

resource "kubernetes_deployment" "portfolio" {
  metadata {
    name      = "portfolio-web"
    namespace = var.namespace
    labels = merge(
      var.tags,
      {
        app       = "portfolio"
        component = "web"
      }
    )
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app       = "portfolio"
        component = "web"
      }
    }

    template {
      metadata {
        labels = {
          app       = "portfolio"
          component = "web"
        }
      }

      spec {
        automount_service_account_token = false

        container {
          name  = "portfolio"
          image = "nginxinc/nginx-unprivileged:1.29-alpine"

          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
            run_as_non_root            = true
            capabilities {
              drop = ["ALL"]
            }
          }

          port {
            container_port = 8080
            name           = "http"
            protocol       = "TCP"
          }

          volume_mount {
            name       = "html"
            mount_path = "/usr/share/nginx/html"
          }

          volume_mount {
            name       = "tmp"
            mount_path = "/tmp"
          }

          volume_mount {
            name       = "nginx-cache"
            mount_path = "/var/cache/nginx"
          }

          volume_mount {
            name       = "nginx-run"
            mount_path = "/var/run"
          }

          resources {
            requests = {
              cpu    = var.cpu_request
              memory = var.memory_request
            }
            limits = {
              cpu    = var.cpu_limit
              memory = var.memory_limit
            }
          }

          liveness_probe {
            http_get {
              path   = "/"
              port   = 8080
              scheme = "HTTP"
            }
            initial_delay_seconds = 10
            period_seconds        = 30
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path   = "/"
              port   = 8080
              scheme = "HTTP"
            }
            initial_delay_seconds = 5
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }
        }

        volume {
          name = "html"
          config_map {
            name = kubernetes_config_map.portfolio_html.metadata[0].name
          }
        }

        volume {
          name = "tmp"
          empty_dir {}
        }

        volume {
          name = "nginx-cache"
          empty_dir {}
        }

        volume {
          name = "nginx-run"
          empty_dir {}
        }
      }
    }
  }

  depends_on = [kubernetes_config_map.portfolio_html]
}

resource "kubernetes_service" "portfolio" {
  metadata {
    name      = "portfolio-web"
    namespace = var.namespace
    labels = merge(
      var.tags,
      {
        app = "portfolio"
      }
    )
  }

  spec {
    selector = {
      app       = "portfolio"
      component = "web"
    }

    port {
      port        = 80
      target_port = 8080
      protocol    = "TCP"
      name        = "http"
    }

    type = "ClusterIP"
  }

  depends_on = [kubernetes_deployment.portfolio]
}

resource "kubernetes_ingress_v1" "portfolio" {
  metadata {
    name      = "portfolio"
    namespace = var.namespace
    labels = merge(
      var.tags,
      {
        app = "portfolio"
      }
    )
    annotations = {
      "cert-manager.io/cluster-issuer" = "local-lan-ca"
    }
  }

  spec {
    ingress_class_name = "nginx"

    tls {
      hosts       = ["portfolio.local.lan"]
      secret_name = "portfolio-tls"
    }

    rule {
      host = "portfolio.local.lan"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.portfolio.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_service.portfolio]
}
