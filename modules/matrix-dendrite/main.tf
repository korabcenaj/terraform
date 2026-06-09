locals {
  oidc_scopes_value = join("\", \"", var.oidc_scopes)

  well_known_server_json = jsonencode({
    "m.server" = "${var.server_name}:443"
  })

  well_known_client_json = jsonencode({
    "m.homeserver" = {
      "base_url" = trimspace(var.public_base_url) != "" ? trimspace(var.public_base_url) : "https://${var.ingress_host}"
    }
  })

  # Federation domain whitelist as comma-separated string
  federation_whitelist_value = join(",", var.federation_domain_whitelist)
}

resource "kubernetes_namespace" "matrix" {
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

data "kubernetes_secret_v1" "local_lan_ca" {
  metadata {
    name      = "local-lan-ca-secret"
    namespace = "cert-manager"
  }
}

resource "kubernetes_secret_v1" "dendrite_oidc_ca" {
  metadata {
    name      = "matrix-dendrite-oidc-ca"
    namespace = kubernetes_namespace.matrix.metadata[0].name
    labels    = var.tags
  }

  type = "Opaque"

  data = {
    "local-lan-ca.crt" = data.kubernetes_secret_v1.local_lan_ca.data["tls.crt"]
  }
}

resource "kubernetes_secret_v1" "dendrite_secrets" {
  metadata {
    name      = "matrix-dendrite-secrets"
    namespace = kubernetes_namespace.matrix.metadata[0].name
    labels    = var.tags
  }

  type = "Opaque"

  data = {
    registrationSharedSecret = var.registration_shared_secret
    oidcClientSecret         = var.oidc_client_secret
    bootstrapAdminPassword   = var.bootstrap_admin_password
  }
}

# ---------------------------------------------------------------------------
# ConfigMap: start script + dendrite.yaml generator + nginx well-known conf
# ---------------------------------------------------------------------------
resource "kubernetes_config_map_v1" "dendrite_config" {
  metadata {
    name      = "matrix-dendrite-config"
    namespace = kubernetes_namespace.matrix.metadata[0].name
    labels    = var.tags
  }

  data = {
    "start.sh" = <<-SH
      #!/bin/sh
      set -eu

      echo "[dendrite] Generating /data/dendrite.yaml ..."

      cat > /data/dendrite.yaml << YAMLEOF
      version: 2

      global:
        server_name: $${SERVER_NAME}
        well_known_server_name: "$${INGRESS_HOST}:443"
        private_key: /data/matrix_key.pem
        key_validity_period: 168h0m0s
        trusted_third_party_id_servers:
          - matrix.org
          - vector.im

      client_api:
        registration_disabled: true
        registration_shared_secret: "$${REGISTRATION_SHARED_SECRET}"
        turn:
          turn_user_lifetime: "5m"
          turn_shared_secret: ""

      media_api:
        base_path: /data/media
        max_file_size_bytes: 10485760

      sync_api:
        real_ip_header: X-Forwarded-For

      federation_api:
        send_max_retries: 16
        disable_federation: $${FEDERATION_DISABLED}
      YAMLEOF

      # Conditionally append OIDC block
      if [ "$${OIDC_ENABLED}" = "true" ]; then
        cat >> /data/dendrite.yaml << YAMLEOF
      oidc:
        enabled: true
        idp_name: "Keycloak"
        issuer: "$${OIDC_ISSUER_URL}"
        client_id: "$${OIDC_CLIENT_ID}"
        client_secret: "$${OIDC_CLIENT_SECRET}"
        scopes: ["$${OIDC_SCOPES}"]
        user_mapping:
          localpart: "{{.preferred_username}}"
          display_name: "{{.name}}"
      YAMLEOF
      fi

      # Append database and logging
      cat >> /data/dendrite.yaml << YAMLEOF

      database:
        connection_string: file:/data/dendrite.db
        max_open_conns: 10
        max_idle_conns: 2
        conn_max_lifetime: -1

      mscs:
        mscs: []

      logging:
        - type: std
          level: info
      YAMLEOF

      echo "[dendrite] Configuration written. Starting Dendrite monolith..."
      exec /usr/bin/dendrite-monolith-server --config /data/dendrite.yaml
    SH

    "default.conf" = <<-NGINX
      server {
        listen 8080;
        server_name _;

        location = /.well-known/matrix/server {
          default_type application/json;
          add_header Access-Control-Allow-Origin "*" always;
          return 200 '${local.well_known_server_json}';
        }

        location = /.well-known/matrix/client {
          default_type application/json;
          add_header Access-Control-Allow-Origin "*" always;
          return 200 '${local.well_known_client_json}';
        }
      }
    NGINX
  }
}

# ---------------------------------------------------------------------------
# Persistent Volume Claim for Dendrite data (SQLite DB, media, signing key)
# ---------------------------------------------------------------------------
resource "kubernetes_persistent_volume_claim" "dendrite_data" {
  metadata {
    name      = "dendrite-data"
    namespace = kubernetes_namespace.matrix.metadata[0].name
    labels    = var.tags
  }

  wait_until_bound = false

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = var.storage_class

    resources {
      requests = {
        storage = var.storage_size
      }
    }
  }
}

# ---------------------------------------------------------------------------
# Dendrite Deployment (monolith)
# ---------------------------------------------------------------------------
resource "kubernetes_deployment" "dendrite" {
  metadata {
    name      = var.name
    namespace = kubernetes_namespace.matrix.metadata[0].name
    labels = merge(var.tags, {
      app = "matrix-dendrite"
    })
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "matrix-dendrite"
      }
    }

    template {
      metadata {
        labels = {
          app = "matrix-dendrite"
        }
      }

      spec {
        automount_service_account_token = false

        container {
          name              = "dendrite"
          image             = var.image
          image_pull_policy = "IfNotPresent"

          command = ["/bin/sh", "/config/start.sh"]

          env {
            name  = "SERVER_NAME"
            value = var.server_name
          }

          env {
            name  = "INGRESS_HOST"
            value = var.ingress_host
          }

          env {
            name = "REGISTRATION_SHARED_SECRET"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.dendrite_secrets.metadata[0].name
                key  = "registrationSharedSecret"
              }
            }
          }

          env {
            name  = "FEDERATION_DISABLED"
            value = var.federation_enabled ? "false" : "true"
          }

          env {
            name  = "OIDC_ENABLED"
            value = var.oidc_enabled ? "true" : "false"
          }

          env {
            name  = "OIDC_ISSUER_URL"
            value = var.oidc_issuer_url
          }

          env {
            name  = "OIDC_CLIENT_ID"
            value = var.oidc_client_id
          }

          env {
            name = "OIDC_CLIENT_SECRET"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.dendrite_secrets.metadata[0].name
                key  = "oidcClientSecret"
              }
            }
          }

          env {
            name  = "OIDC_SCOPES"
            value = local.oidc_scopes_value
          }

          port {
            name           = "http"
            container_port = 8008
            protocol       = "TCP"
          }

          volume_mount {
            name       = "dendrite-data"
            mount_path = "/data"
          }

          volume_mount {
            name       = "dendrite-config"
            mount_path = "/config"
          }

          volume_mount {
            name       = "oidc-ca"
            mount_path = "/usr/local/share/ca-certificates/local-lan-ca.crt"
            sub_path   = "local-lan-ca.crt"
            read_only  = true
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
              path   = "/_matrix/client/versions"
              port   = 8008
              scheme = "HTTP"
            }
            initial_delay_seconds = 30
            period_seconds        = 20
            timeout_seconds       = 5
            failure_threshold     = 6
          }

          readiness_probe {
            http_get {
              path   = "/_matrix/client/versions"
              port   = 8008
              scheme = "HTTP"
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 6
          }
        }

        volume {
          name = "dendrite-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.dendrite_data.metadata[0].name
          }
        }

        volume {
          name = "dendrite-config"
          config_map {
            name = kubernetes_config_map_v1.dendrite_config.metadata[0].name
          }
        }

        volume {
          name = "oidc-ca"
          secret {
            secret_name = kubernetes_secret_v1.dendrite_oidc_ca.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_secret_v1.dendrite_secrets,
    kubernetes_secret_v1.dendrite_oidc_ca,
    kubernetes_config_map_v1.dendrite_config,
    kubernetes_persistent_volume_claim.dendrite_data,
  ]
}

# ---------------------------------------------------------------------------
# Service
# ---------------------------------------------------------------------------
resource "kubernetes_service" "dendrite" {
  metadata {
    name      = var.name
    namespace = kubernetes_namespace.matrix.metadata[0].name
    labels = merge(var.tags, {
      app = "matrix-dendrite"
    })
  }

  spec {
    selector = {
      app = "matrix-dendrite"
    }

    port {
      name        = "http"
      port        = 8008
      target_port = 8008
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }

  depends_on = [kubernetes_deployment.dendrite]
}

# ---------------------------------------------------------------------------
# NetworkPolicy: allow OIDC egress when enabled
# ---------------------------------------------------------------------------
resource "kubernetes_network_policy" "dendrite_oidc_egress" {
  count = var.oidc_enabled ? 1 : 0

  metadata {
    name      = "matrix-dendrite-allow-oidc-egress"
    namespace = kubernetes_namespace.matrix.metadata[0].name
    labels    = var.tags
  }

  spec {
    pod_selector {
      match_labels = {
        app = "matrix-dendrite"
      }
    }

    policy_types = ["Egress"]

    egress {
      to {
        ip_block {
          cidr = "0.0.0.0/0"
        }
      }

      ports {
        protocol = "TCP"
        port     = 443
      }
    }
  }
}

# ---------------------------------------------------------------------------
# Bootstrap admin user Job (one-shot)
# ---------------------------------------------------------------------------
resource "kubernetes_job_v1" "bootstrap_admin" {
  count = var.bootstrap_admin_enabled ? 1 : 0

  metadata {
    name      = "matrix-dendrite-bootstrap-admin"
    namespace = kubernetes_namespace.matrix.metadata[0].name
    labels    = var.tags
  }

  wait_for_completion = false

  spec {
    backoff_limit = 3

    template {
      metadata {
        labels = {
          app = "matrix-dendrite-bootstrap-admin"
        }
      }

      spec {
        restart_policy = "OnFailure"

        container {
          name  = "bootstrap-admin"
          image = var.image

          command = [
            "/bin/sh",
            "-c",
            <<-CMD
              set -eu

              echo "[bootstrap] Waiting for Dendrite to become ready..."
              for i in $(seq 1 90); do
                if wget -q -O /dev/null http://${var.name}:8008/_matrix/client/versions 2>/dev/null; then
                  echo "[bootstrap] Dendrite is ready."
                  break
                fi
                sleep 2
              done

              echo "[bootstrap] Creating admin user '$${MATRIX_BOOTSTRAP_ADMIN_USERNAME}'..."
              /usr/bin/create-account \
                -config /data/dendrite.yaml \
                -username "$${MATRIX_BOOTSTRAP_ADMIN_USERNAME}" \
                -password "$${MATRIX_BOOTSTRAP_ADMIN_PASSWORD}" \
                -admin || true

              echo "[bootstrap] Done."
            CMD
          ]

          env {
            name  = "MATRIX_BOOTSTRAP_ADMIN_USERNAME"
            value = var.bootstrap_admin_username
          }

          env {
            name = "MATRIX_BOOTSTRAP_ADMIN_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.dendrite_secrets.metadata[0].name
                key  = "bootstrapAdminPassword"
              }
            }
          }

          volume_mount {
            name       = "dendrite-config"
            mount_path = "/config"
          }
        }

        volume {
          name = "dendrite-config"
          config_map {
            name = kubernetes_config_map_v1.dendrite_config.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [kubernetes_service.dendrite]
}

# ---------------------------------------------------------------------------
# Well-known Deployment (nginx)
# ---------------------------------------------------------------------------
resource "kubernetes_deployment" "well_known" {
  count = var.well_known_enabled ? 1 : 0

  metadata {
    name      = "matrix-well-known"
    namespace = kubernetes_namespace.matrix.metadata[0].name
    labels = merge(var.tags, {
      app = "matrix-well-known"
    })
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "matrix-well-known"
      }
    }

    template {
      metadata {
        labels = {
          app = "matrix-well-known"
        }
      }

      spec {
        automount_service_account_token = false

        container {
          name  = "well-known"
          image = "nginxinc/nginx-unprivileged:1.29-alpine"

          port {
            name           = "http"
            container_port = 8080
          }

          volume_mount {
            name       = "nginx-default"
            mount_path = "/etc/nginx/conf.d/default.conf"
            sub_path   = "default.conf"
          }

          resources {
            requests = {
              cpu    = "25m"
              memory = "32Mi"
            }
            limits = {
              cpu    = "100m"
              memory = "64Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/.well-known/matrix/server"
              port = 8080
            }
            initial_delay_seconds = 10
            period_seconds        = 30
          }

          readiness_probe {
            http_get {
              path = "/.well-known/matrix/server"
              port = 8080
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }
        }

        volume {
          name = "nginx-default"
          config_map {
            name = kubernetes_config_map_v1.dendrite_config.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [kubernetes_config_map_v1.dendrite_config]
}

resource "kubernetes_service" "well_known" {
  count = var.well_known_enabled ? 1 : 0

  metadata {
    name      = "matrix-well-known"
    namespace = kubernetes_namespace.matrix.metadata[0].name
    labels = merge(var.tags, {
      app = "matrix-well-known"
    })
  }

  spec {
    selector = {
      app = "matrix-well-known"
    }

    port {
      name        = "http"
      port        = 8080
      target_port = 8080
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }

  depends_on = [kubernetes_deployment.well_known]
}

# ---------------------------------------------------------------------------
# Ingress
# ---------------------------------------------------------------------------
resource "kubernetes_ingress_v1" "dendrite" {
  metadata {
    name      = "matrix-dendrite"
    namespace = kubernetes_namespace.matrix.metadata[0].name
    labels    = var.tags
    annotations = {
      "cert-manager.io/cluster-issuer" = var.cluster_issuer
    }
  }

  spec {
    ingress_class_name = "traefik"

    tls {
      hosts       = [var.ingress_host]
      secret_name = "matrix-dendrite-tls"
    }

    rule {
      host = var.ingress_host
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.dendrite.metadata[0].name
              port {
                number = 8008
              }
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_service.dendrite]
}

resource "kubernetes_ingress_v1" "well_known" {
  count = var.well_known_enabled ? 1 : 0

  metadata {
    name      = "matrix-well-known"
    namespace = kubernetes_namespace.matrix.metadata[0].name
    labels    = var.tags
  }

  spec {
    ingress_class_name = "traefik"

    rule {
      host = var.ingress_host
      http {
        path {
          path      = "/.well-known/matrix/server"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.well_known[0].metadata[0].name
              port {
                number = 8080
              }
            }
          }
        }

        path {
          path      = "/.well-known/matrix/client"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.well_known[0].metadata[0].name
              port {
                number = 8080
              }
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_service.well_known]
}
