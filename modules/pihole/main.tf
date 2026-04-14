# Pi-hole web password stored as a Kubernetes Secret
resource "kubernetes_secret" "pihole_web_password" {
  metadata {
    name      = "pihole-web-password"
    namespace = var.namespace
    labels    = var.tags
  }

  data = {
    WEBPASSWORD = var.web_password
  }

  type = "Opaque"
}

# Custom DNS records for local LAN resolution
# Wildcard *.<domain> -> ingress IP plus any additional explicit records
resource "kubernetes_config_map" "pihole_custom_dns" {
  metadata {
    name      = "pihole-custom-dns"
    namespace = var.namespace
    labels    = var.tags
  }

  data = {
    "02-local-dns.conf" = join("\n", concat(
      ["# Wildcard DNS for ${var.dns_wildcard_domain} -> ingress controller"],
      ["address=/${var.dns_wildcard_domain}/${var.ingress_ip}"],
      [""],
      ["# Additional custom DNS records"],
      [for hostname, ip in var.local_dns_records : "host-record=${hostname},${ip}"],
    ))
  }
}

# PersistentVolumeClaim for Pi-hole data
resource "kubernetes_persistent_volume_claim" "pihole_data" {
  metadata {
    name      = "pihole-data"
    namespace = var.namespace
    labels    = var.tags
  }
  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "local-path"
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

    strategy {
      type = "Recreate"
    }

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
        host_network = true
        dns_policy   = "ClusterFirstWithHostNet"
        affinity {
          node_affinity {
            required_during_scheduling_ignored_during_execution {
              node_selector_term {
                match_expressions {
                  key      = "kubernetes.io/hostname"
                  operator = "NotIn"
                  values   = ["k8s3"]
                }
              }
            }
          }
        }
        volume {
          name = "pihole-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.pihole_data.metadata[0].name
          }
        }
        volume {
          name = "custom-dns"
          config_map {
            name = kubernetes_config_map.pihole_custom_dns.metadata[0].name
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
            name = "WEBPASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.pihole_web_password.metadata[0].name
                key  = "WEBPASSWORD"
              }
            }
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

          env {
            name  = "INTERFACE"
            value = "all"
          }

          env {
            name  = "FTLCONF_dns_listeningMode"
            value = "all"
          }

          env {
            name  = "FTLCONF_misc_etc_dnsmasq_d"
            value = "true"
          }

          env {
            name  = "VIRTUAL_HOST"
            value = var.ingress_host
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

          volume_mount {
            name       = "custom-dns"
            mount_path = "/etc/dnsmasq.d/02-local-dns.conf"
            sub_path   = "02-local-dns.conf"
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

  lifecycle {
    ignore_changes = [metadata[0].annotations]
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
    annotations = {
      "cert-manager.io/cluster-issuer" = "local-lan-ca"
    }
  }

  spec {
    ingress_class_name = "nginx"

    tls {
      hosts       = [var.ingress_host]
      secret_name = "pihole-tls"
    }

    rule {
      host = var.ingress_host
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
