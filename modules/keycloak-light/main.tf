################################################################################
# Keycloak Light — minimal OIDC identity provider
# Uses official Quarkus-based image with H2 file database.
# No bundled PostgreSQL, no config-cli — just the essentials.
################################################################################

resource "kubernetes_namespace" "keycloak" {
  metadata {
    name = var.namespace
    labels = merge(var.tags, {
      name                                 = var.namespace
      "pod-security.kubernetes.io/enforce" = "baseline"
    })
  }
}

# PVC for H2 file database persistence
resource "kubernetes_persistent_volume_claim_v1" "keycloak_data" {
  metadata {
    name      = "${var.name}-data"
    namespace = kubernetes_namespace.keycloak.metadata[0].name
    labels    = merge(var.tags, { app = var.name })
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.storage_size
      }
    }
    storage_class_name = var.storage_class
  }
}

resource "kubernetes_deployment_v1" "keycloak" {
  metadata {
    name      = var.name
    namespace = kubernetes_namespace.keycloak.metadata[0].name
    labels    = merge(var.tags, { app = var.name })
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = { app = var.name }
    }

    template {
      metadata {
        labels = { app = var.name }
      }

      spec {
        container {
          name  = var.name
          image = var.image
          args  = ["start-dev"]

          port {
            name           = "http"
            container_port = 8080
            protocol       = "TCP"
          }

          env {
            name  = "KC_BOOTSTRAP_ADMIN_USERNAME"
            value = var.admin_user
          }

          env {
            name  = "KC_BOOTSTRAP_ADMIN_PASSWORD"
            value = var.admin_password
          }

          env {
            name  = "KC_DB"
            value = "dev-file"
          }

          env {
            name  = "KC_HTTP_ENABLED"
            value = "true"
          }

          env {
            name  = "KC_HOSTNAME"
            value = var.ingress_host
          }

          env {
            name  = "KC_PROXY_HEADERS"
            value = "xforwarded"
          }

          env {
            name  = "KC_HTTP_RELATIVE_PATH"
            value = "/"
          }

          env {
            name  = "KC_HEALTH_ENABLED"
            value = "true"
          }

          env {
            name  = "KC_METRICS_ENABLED"
            value = "true"
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

          readiness_probe {
            http_get {
              path = "/"
              port = 8080
            }
            initial_delay_seconds = 180
            period_seconds        = 15
            failure_threshold     = 20
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 8080
            }
            initial_delay_seconds = 240
            period_seconds        = 30
            failure_threshold     = 10
          }

          volume_mount {
            name       = "data"
            mount_path = "/opt/keycloak/data"
          }
        }

        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.keycloak_data.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "keycloak" {
  metadata {
    name      = var.name
    namespace = kubernetes_namespace.keycloak.metadata[0].name
    labels    = merge(var.tags, { app = var.name })
  }

  spec {
    selector = { app = var.name }

    port {
      name        = "http"
      port        = 80
      target_port = "http"
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_ingress_v1" "keycloak" {
  metadata {
    name      = var.name
    namespace = kubernetes_namespace.keycloak.metadata[0].name
    labels    = merge(var.tags, { app = var.name })
    annotations = {
      "cert-manager.io/cluster-issuer"                   = "local-lan-ca"
      "traefik.ingress.kubernetes.io/router.entrypoints" = "websecure"
      "traefik.ingress.kubernetes.io/router.tls"         = "true"
    }
  }

  spec {
    tls {
      hosts       = [var.ingress_host]
      secret_name = "${var.name}-tls"
    }

    rule {
      host = var.ingress_host
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service_v1.keycloak.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_deployment_v1.keycloak]
}
