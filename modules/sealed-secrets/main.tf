# Sealed Secrets controller deployed in kube-system
# Managed via raw Kubernetes manifests, not Helm

resource "kubernetes_service_account" "sealed_secrets" {
  metadata {
    name      = "sealed-secrets-controller"
    namespace = "kube-system"
  }
}

resource "kubernetes_deployment" "sealed_secrets" {
  metadata {
    name      = "sealed-secrets-controller"
    namespace = "kube-system"
    labels = merge(var.tags, {
      name = "sealed-secrets-controller"
    })
  }

  spec {
    replicas = 1
    min_ready_seconds = 30

    selector {
      match_labels = {
        name = "sealed-secrets-controller"
      }
    }

    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_surge       = "25%"
        max_unavailable = "25%"
      }
    }

    template {
      metadata {
        labels = {
          name = "sealed-secrets-controller"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.sealed_secrets.metadata[0].name

        container {
          name  = "sealed-secrets-controller"
          image = var.image

          command = ["controller"]

          port {
            name           = "http"
            container_port = 8080
          }

          liveness_probe {
            http_get {
              path = "/healthz"
              port = "http"
            }
          }

          readiness_probe {
            http_get {
              path = "/healthz"
              port = "http"
            }
          }

          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem = true
            capabilities {
              drop = ["ALL"]
            }
          }

          volume_mount {
            name       = "tmp"
            mount_path = "/tmp"
          }
        }

        security_context {
          run_as_non_root = true
          run_as_user     = 1001
          fs_group        = 65534
          seccomp_profile {
            type = "RuntimeDefault"
          }
        }

        volume {
          name = "tmp"
          empty_dir {}
        }
      }
    }
  }
}
