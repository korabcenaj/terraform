resource "kubernetes_config_map" "portfolio_static" {
  metadata {
    name      = "portfolio-static"
    namespace = var.namespace
    labels = merge(
      var.tags,
      {
        app = "portfolio"
      }
    )
  }

  data = var.configmap_files != {} ? {
    for filename, filepath in var.configmap_files :
    filename => file(filepath)
  } : {
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
    replicas = var.keda_enabled ? 0 : var.replicas

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
        dynamic "image_pull_secrets" {
          for_each = var.image_pull_secrets
          content {
            name = image_pull_secrets.value
          }
        }

        security_context {
          run_as_non_root = true
          seccomp_profile {
            type = "RuntimeDefault"
          }
        }

        automount_service_account_token = false

        container {
          name  = "portfolio"
          image = var.image

          image_pull_policy = "IfNotPresent"

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
            name       = "portfolio-static"
            mount_path = "/usr/share/nginx/html"
            read_only  = true
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
          name = "portfolio-static"
          config_map {
            name = kubernetes_config_map.portfolio_static.metadata[0].name
            default_mode = "0420"
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

  depends_on = [kubernetes_config_map.portfolio_static]
}

resource "kubernetes_manifest" "portfolio_idle_scaler" {
  count = var.keda_enabled ? 1 : 0

  manifest = {
    apiVersion = "keda.sh/v1alpha1"
    kind       = "ScaledObject"
    metadata = {
      name      = "portfolio-idle-scaler"
      namespace = var.namespace
      labels = {
        "scaling-tier"                     = "demand"
        "app.kubernetes.io/component"      = "idle-scaler"
      }
    }
    spec = {
      scaleTargetRef = {
        apiVersion = "apps/v1"
        kind       = "Deployment"
        name       = "portfolio-web"
      }
      minReplicaCount = var.keda_min_replicas
      maxReplicaCount = var.keda_max_replicas
      cooldownPeriod  = 600
      triggers = [
        {
          type = "cron"
          metadata = {
            timezone         = var.keda_timezone
            start            = var.keda_cron_start
            end              = var.keda_cron_end
            desiredReplicas  = var.keda_desired_replicas
          }
        }
      ]
    }
  }

  depends_on = [kubernetes_deployment.portfolio]
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
    annotations = merge(
      { "cert-manager.io/cluster-issuer" = "local-lan-ca" },
      var.oauth2_proxy_middleware != "" ? {
        "traefik.ingress.kubernetes.io/router.middlewares" = var.oauth2_proxy_middleware
      } : {}
    )
  }

  spec {
    ingress_class_name = "traefik"

    tls {
      hosts       = [var.ingress_host]
      secret_name = "portfolio-tls"
    }

    rule {
      host = var.ingress_host
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
