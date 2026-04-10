resource "kubernetes_persistent_volume_claim" "jellyfin_config" {
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
        container {
          name  = "jellyfin"
          image = "jellyfin/jellyfin:latest"

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
      }
    }
  }

  depends_on = [
    kubernetes_persistent_volume_claim.jellyfin_config,
    kubernetes_persistent_volume_claim.jellyfin_cache
  ]
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

    type = "ClusterIP"
  }

  depends_on = [kubernetes_deployment.jellyfin]
}
