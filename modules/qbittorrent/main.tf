resource "kubernetes_persistent_volume" "qbit_config" {
  metadata {
    name = "qbit-config-pv"
  }

  spec {
    capacity = {
      storage = "5Gi"
    }

    access_modes = ["ReadWriteOnce"]

    persistent_volume_source {
      local {
        path = "/home/kub/qbittorrent-data"
      }
    }

    node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key      = "kubernetes.io/hostname"
            operator = "In"
            values   = ["k8s"]
          }
        }
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "qbit_config" {
  metadata {
    name      = "qbit-config-pvc"
    namespace = var.namespace
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = "5Gi"
      }
    }

    volume_name = kubernetes_persistent_volume.qbit_config.metadata[0].name
  }

  depends_on = [kubernetes_persistent_volume.qbit_config]
}

resource "kubernetes_deployment" "qbittorrent" {
  metadata {
    name      = "qbittorrent"
    namespace = var.namespace
    labels = merge(
      var.tags,
      {
        app = "qbittorrent"
      }
    )
  }

  spec {
    replicas = var.replicas

    strategy {
      type = "Recreate"
    }

    selector {
      match_labels = {
        app = "qbittorrent"
      }
    }

    template {
      metadata {
        labels = {
          app = "qbittorrent"
        }
      }

      spec {
        container {
          name              = "qbittorrent"
          image             = "linuxserver/qbittorrent:5.1.4"
          image_pull_policy = "IfNotPresent"

          port {
            container_port = 8080
            name           = "web"
            protocol       = "TCP"
          }

          env {
            name  = "WEBUI_PORT"
            value = "8080"
          }

          volume_mount {
            name       = "config"
            mount_path = "/config"
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
            initial_delay_seconds = 30
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
            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }
        }

        volume {
          name = "config"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.qbit_config.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [kubernetes_persistent_volume_claim.qbit_config]
}

resource "kubernetes_service" "qbittorrent" {
  metadata {
    name      = "qbittorrent"
    namespace = var.namespace
    labels = merge(
      var.tags,
      {
        app = "qbittorrent"
      }
    )
  }

  spec {
    selector = {
      app = "qbittorrent"
    }

    port {
      port        = 8080
      target_port = 8080
      protocol    = "TCP"
      name        = "web"
    }

    type = "ClusterIP"
  }

  depends_on = [kubernetes_deployment.qbittorrent]
}

resource "kubernetes_ingress_v1" "qbittorrent" {
  metadata {
    name      = "qbittorrent"
    namespace = var.namespace
    labels = merge(
      var.tags,
      {
        app = "qbittorrent"
      }
    )
    annotations = {
      "cert-manager.io/cluster-issuer" = "local-lan-ca"
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
                number = 8080
              }
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_service.qbittorrent]
}
