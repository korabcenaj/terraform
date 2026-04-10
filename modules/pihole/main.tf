# PersistentVolumeClaim for Pi-hole data
resource "kubernetes_persistent_volume_claim" "pihole_data" {
  metadata {
    name      = "pihole-data"
    namespace = var.namespace
    labels    = var.tags
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.pihole_storage_size
      }
    }
  }
}
# Pi-hole DNS and ad-blocking module
# Provides network-wide DNS and ad filtering

resource "kubernetes_deployment" "pihole" {
  metadata {
    name      = "pihole"
    namespace = var.namespace
    labels = merge(
      var.tags,
      {
        app = "pihole"
      }
    )
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app = "pihole"
      }
    }

    template {
      metadata {
        labels = {
          app = "pihole"
        }
      }

      spec {
        volume {
          name = "pihole-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.pihole_data.metadata[0].name
          }
        }
        container {
          name              = "pihole"
          image             = var.image
          image_pull_policy = "IfNotPresent"

          port {
            container_port = 53
            name           = "dns"
            protocol       = "UDP"
          }

          port {
            container_port = 53
            name           = "dns-tcp"
            protocol       = "TCP"
          }

          port {
            container_port = 80
            name           = "web"
            protocol       = "TCP"
          }

          port {
            container_port = 443
            name           = "https"
            protocol       = "TCP"
          }

          env {
            name  = "TZ"
            value = var.timezone
          }

          env {
            name  = "WEBPASSWORD"
            value = var.web_password
          }

          env {
            name  = "DNS1"
            value = "8.8.8.8"
          }

          env {
            name  = "DNS2"
            value = "8.8.4.4"
          }

          env {
            name  = "DNSMASQ_LISTENING"
            value = "all"
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

          volume_mount {
            name       = "pihole-data"
            mount_path = "/etc/pihole"
          }

          liveness_probe {
            http_get {
              path   = "/admin"
              port   = 80
              scheme = "HTTP"
            }
            initial_delay_seconds = 30
            period_seconds        = 30
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path   = "/admin"
              port   = 80
              scheme = "HTTP"
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "pihole" {
  metadata {
    name      = "pihole"
    namespace = var.namespace
    labels = merge(
      var.tags,
      {
        app = "pihole"
      }
    )
  }

  spec {
    selector = {
      app = "pihole"
    }

    port {
      port        = 53
      target_port = 53
      protocol    = "UDP"
      name        = "dns-udp"
    }

    port {
      port        = 53
      target_port = 53
      protocol    = "TCP"
      name        = "dns-tcp"
    }

    port {
      port        = 80
      target_port = 80
      protocol    = "TCP"
      name        = "web"
    }

    port {
      port        = 443
      target_port = 443
      protocol    = "TCP"
      name        = "https"
    }

    type = "LoadBalancer"
  }

  depends_on = [kubernetes_deployment.pihole]
}

resource "kubernetes_ingress_v1" "pihole" {
  metadata {
    name      = "pihole"
    namespace = var.namespace
    labels = merge(
      var.tags,
      {
        app = "pihole"
      }
    )
  }

  spec {
    ingress_class_name = "nginx"

    rule {
      host = "pihole.local.lan"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.pihole.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_service.pihole]
}
