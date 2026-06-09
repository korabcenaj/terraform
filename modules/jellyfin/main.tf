resource "kubernetes_persistent_volume_claim" "jellyfin_config" {
  wait_until_bound = false

  metadata {
    name      = "jellyfin-config"
    namespace = var.namespace
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = var.storage_class

    resources {
      requests = {
        storage = var.config_size
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "jellyfin_cache" {
  wait_until_bound = false

  metadata {
    name      = "jellyfin-cache"
    namespace = var.namespace
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = var.storage_class

    resources {
      requests = {
        storage = var.cache_size
      }
    }
  }
}

resource "kubernetes_deployment" "jellyfin" {
  wait_for_rollout = false

  metadata {
    name      = "jellyfin"
    namespace = var.namespace
    labels = merge(
      var.tags,
      {
        app = "jellyfin"
      }
    )
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app = "jellyfin"
      }
    }

    template {
      metadata {
        labels = {
          app = "jellyfin"
        }
      }

      spec {
        node_selector = {
          "kubernetes.io/hostname" = var.node_name
        }

        toleration {
          key    = "node-role.kubernetes.io/control-plane"
          effect = "NoSchedule"
        }

        automount_service_account_token = false

        security_context {
          seccomp_profile {
            type = "RuntimeDefault"
          }
        }

        container {
          name  = "jellyfin"
          image = var.image

          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
            capabilities {
              drop = ["ALL"]
            }
          }

          port {
            container_port = 8096
            name           = "web"
            protocol       = "TCP"
          }

          env {
            name  = "JELLYFIN_CONFIG_DIR"
            value = "/config"
          }

          env {
            name  = "JELLYFIN_CACHE_DIR"
            value = "/cache"
          }

          volume_mount {
            name       = "config"
            mount_path = "/config"
          }

          volume_mount {
            name       = "cache"
            mount_path = "/cache"
          }

          volume_mount {
            name       = "media"
            mount_path = "/media"
          }

          volume_mount {
            name       = "tmp"
            mount_path = "/tmp"
          }

          resources {
            requests = merge(
              {
                cpu    = var.cpu_request
                memory = var.memory_request
              },
              var.gpu_count > 0 ? { (var.gpu_resource_name) = tostring(var.gpu_count) } : {}
            )
            limits = merge(
              {
                cpu    = var.cpu_limit
                memory = var.memory_limit
              },
              var.gpu_count > 0 ? { (var.gpu_resource_name) = tostring(var.gpu_count) } : {}
            )
          }

          startup_probe {
            tcp_socket {
              port = 8096
            }
            initial_delay_seconds = 0
            period_seconds        = 10
            timeout_seconds       = 1
            success_threshold     = 1
            failure_threshold     = 30
          }

          liveness_probe {
            http_get {
              path   = "/health"
              port   = 8096
              scheme = "HTTP"
            }
            initial_delay_seconds = 30
            period_seconds        = 30
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path   = "/health"
              port   = 8096
              scheme = "HTTP"
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }
        }

        volume {
          name = "config"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.jellyfin_config.metadata[0].name
          }
        }

        volume {
          name = "cache"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.jellyfin_cache.metadata[0].name
          }
        }

        volume {
          name = "media"
          persistent_volume_claim {
            claim_name = var.media_pvc_name
          }
        }

        volume {
          name = "tmp"
          empty_dir {}
        }
      }
    }
  }

  depends_on = [
    kubernetes_persistent_volume_claim.jellyfin_config,
    kubernetes_persistent_volume_claim.jellyfin_cache
  ]

  lifecycle {
    ignore_changes = [metadata[0].annotations]
  }
}

resource "kubernetes_service" "jellyfin" {
  metadata {
    name      = "jellyfin"
    namespace = var.namespace
    labels = merge(
      var.tags,
      {
        app = "jellyfin"
      }
    )
  }

  spec {
    selector = {
      app = "jellyfin"
    }

    port {
      port        = 8096
      target_port = 8096
      protocol    = "TCP"
      name        = "web"
    }

    type = var.load_balancer_ip != "" ? "LoadBalancer" : "ClusterIP"
    load_balancer_ip = var.load_balancer_ip != "" ? var.load_balancer_ip : null
  }

  depends_on = [kubernetes_deployment.jellyfin]
}

resource "kubernetes_ingress_v1" "jellyfin" {
  metadata {
    name      = "jellyfin"
    namespace = var.namespace
    labels = merge(
      var.tags,
      {
        app = "jellyfin"
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
      secret_name = "jellyfin-tls"
    }

    rule {
      host = var.ingress_host
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.jellyfin.metadata[0].name
              port {
                number = 8096
              }
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_service.jellyfin]
}
