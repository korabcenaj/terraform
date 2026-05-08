resource "kubernetes_namespace" "cloudflare_tunnel" {
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

resource "kubernetes_deployment" "cloudflared" {
  metadata {
    name      = var.name
    namespace = kubernetes_namespace.cloudflare_tunnel.metadata[0].name
    labels = merge(var.tags, {
      app = "cloudflared"
    })
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app = "cloudflared"
      }
    }

    template {
      metadata {
        labels = {
          app = "cloudflared"
        }
      }

      spec {
        automount_service_account_token = false

        container {
          name              = "cloudflared"
          image             = var.image
          image_pull_policy = "IfNotPresent"

          # cloudflared natively reads TUNNEL_TOKEN from the environment.
          # Using exec form (no shell) so signals are delivered directly to cloudflared.
          command = ["cloudflared"]
          args    = ["tunnel", "--no-autoupdate", "run"]

          env {
            name = "TUNNEL_TOKEN"
            value_from {
              secret_key_ref {
                # Pre-created out-of-band — token never enters Terraform state
                name = var.tunnel_token_secret_name
                key  = "token"
              }
            }
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
        }
      }
    }
  }

}
