################################################################################
# qBittorrent — Deployment, PVCs, Service, Ingress
#
# Uses the linuxserver/qbittorrent image which runs as an unprivileged user
# via PUID/PGID environment variables.
################################################################################

resource "kubernetes_persistent_volume_claim" "config" {
  wait_until_bound = false

  metadata {
    name      = "qbittorrent-config"
    namespace = var.namespace
    labels    = var.tags
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

  lifecycle {
    prevent_destroy = true
  }
}

resource "kubernetes_persistent_volume_claim" "downloads" {
  wait_until_bound = false

  metadata {
    name      = "qbittorrent-downloads"
    namespace = var.namespace
    labels    = var.tags
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = var.storage_class

    resources {
      requests = {
        storage = var.downloads_size
      }
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "kubernetes_deployment" "qbittorrent" {
  metadata {
    name      = "qbittorrent"
    namespace = var.namespace
    labels    = merge(var.tags, { app = "qbittorrent" })
  }

  spec {
    replicas = var.replicas

    strategy {
      type = "Recreate"
    }

    selector {
      match_labels = { app = "qbittorrent" }
    }

    template {
      metadata {
        labels = merge(var.tags, { app = "qbittorrent" })
      }

      spec {
        automount_service_account_token = false

        dynamic "affinity" {
          for_each = var.node_name != "" ? [1] : []
          content {
            node_affinity {
              required_during_scheduling_ignored_during_execution {
                node_selector_term {
                  match_expressions {
                    key      = "kubernetes.io/hostname"
                    operator = "In"
                    values   = [var.node_name]
                  }
                }
              }
            }
          }
        }

        container {
          name  = "qbittorrent"
          image = var.image

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

          env {
            name  = "PUID"
            value = tostring(var.puid)
          }

          env {
            name  = "PGID"
            value = tostring(var.pgid)
          }

          env {
            name  = "TZ"
            value = var.timezone
          }

          env {
            name  = "WEBUI_PORT"
            value = tostring(var.web_ui_port)
          }

          port {
            container_port = var.web_ui_port
            name           = "web"
            protocol       = "TCP"
          }

          port {
            container_port = var.torrent_port
            name           = "torrent-tcp"
            protocol       = "TCP"
          }

          port {
            container_port = var.torrent_port
            name           = "torrent-udp"
            protocol       = "UDP"
          }

          volume_mount {
            name       = "config"
            mount_path = "/config"
          }

          volume_mount {
            name       = "downloads"
            mount_path = "/downloads"
          }
        }

        volume {
          name = "config"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.config.metadata[0].name
          }
        }

        volume {
          name = "downloads"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.downloads.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "qbittorrent" {
  metadata {
    name      = "qbittorrent"
    namespace = var.namespace
    labels    = merge(var.tags, { app = "qbittorrent" })
  }

  spec {
    selector = { app = "qbittorrent" }
    type     = "ClusterIP"

    port {
      name        = "web"
      port        = var.web_ui_port
      target_port = var.web_ui_port
      protocol    = "TCP"
    }
  }
}

resource "kubernetes_ingress_v1" "qbittorrent" {
  metadata {
    name      = "qbittorrent"
    namespace = var.namespace
    labels    = var.tags
    annotations = {
      "cert-manager.io/cluster-issuer"                 = "local-lan-ca"
      "nginx.ingress.kubernetes.io/proxy-body-size"    = "0"
      "nginx.ingress.kubernetes.io/proxy-read-timeout" = "600"
      "nginx.ingress.kubernetes.io/proxy-send-timeout" = "600"
    }
  }

  spec {
    ingress_class_name = "nginx"

    tls {
      hosts       = [var.ingress_host]
      secret_name = "qbittorrent-tls"
    }

    rule {
      host = var.ingress_host
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.qbittorrent.metadata[0].name
              port {
                number = var.web_ui_port
              }
            }
          }
        }
      }
    }
  }
}
