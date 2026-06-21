locals {
  oidc_scopes_value = join(",", var.oidc_scopes)

  federation_whitelist_value = join(",", var.federation_domain_whitelist)

  well_known_server_json = jsonencode({
    "m.server" = "${var.server_name}:443"
  })

  well_known_client_json = jsonencode({
    "m.homeserver" = {
      "base_url" = trimspace(var.public_base_url) != "" ? trimspace(var.public_base_url) : "https://${var.ingress_host}"
    }
  })
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

resource "kubernetes_secret_v1" "synapse_oidc_ca" {
  metadata {
    name      = "matrix-synapse-oidc-ca"
    namespace = kubernetes_namespace.matrix.metadata[0].name
    labels    = var.tags
  }

  type = "Opaque"

  data = {
    "local-lan-ca.crt" = data.kubernetes_secret_v1.local_lan_ca.data["tls.crt"]
  }
}

resource "kubernetes_secret_v1" "synapse_secrets" {
  metadata {
    name      = "matrix-synapse-secrets"
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

resource "kubernetes_config_map_v1" "bootstrap_scripts" {
  metadata {
    name      = "matrix-synapse-bootstrap"
    namespace = kubernetes_namespace.matrix.metadata[0].name
    labels    = var.tags
  }

  data = {
    "start.sh" = <<-SH
      #!/bin/sh
      set -eu

      if [ -f /usr/local/share/ca-certificates/local-lan-ca.crt ]; then
        update-ca-certificates >/dev/null 2>&1 || true
      fi

      if [ ! -f /data/homeserver.yaml ]; then
        python -m synapse.app.homeserver \
          --server-name "$${SYNAPSE_SERVER_NAME}" \
          --report-stats "$${SYNAPSE_REPORT_STATS}" \
          --config-path /data/homeserver.yaml \
          --generate-config
      fi

      python /bootstrap/bootstrap-config.py
      exec python -m synapse.app.homeserver --config-path /data/homeserver.yaml
    SH

    "bootstrap-config.py" = <<-PY
      import os
      import yaml

      config_path = "/data/homeserver.yaml"

      with open(config_path, "r", encoding="utf-8") as f:
          cfg = yaml.safe_load(f) or {}

      cfg["enable_registration"] = False
      cfg["enable_registration_without_verification"] = False
      cfg["registration_shared_secret"] = os.environ["MATRIX_REGISTRATION_SHARED_SECRET"]
      cfg["public_baseurl"] = os.environ["MATRIX_PUBLIC_BASEURL"]
      cfg["allow_public_rooms_without_auth"] = False
      cfg["daemonize"] = False
      cfg["listeners"] = [
          {
              "port": 8008,
              "tls": False,
              "type": "http",
              "x_forwarded": True,
              "resources": [
                  {"names": ["client", "federation"], "compress": False}
              ],
              "bind_addresses": ["0.0.0.0"],
          }
      ]

      federation_enabled = os.environ.get("MATRIX_FEDERATION_ENABLED", "false").lower() == "true"
      federation_whitelist = [
          x.strip() for x in os.environ.get("MATRIX_FEDERATION_DOMAIN_WHITELIST", "").split(",") if x.strip()
      ]

      if federation_enabled:
          if federation_whitelist:
              cfg["federation_domain_whitelist"] = federation_whitelist
          else:
              cfg.pop("federation_domain_whitelist", None)
          cfg["allow_public_rooms_over_federation"] = True
      else:
          cfg["federation_domain_whitelist"] = ["localhost.invalid"]
          cfg["allow_public_rooms_over_federation"] = False

      oidc_enabled = os.environ.get("MATRIX_OIDC_ENABLED", "false").lower() == "true"
      if oidc_enabled:
          scopes = [x.strip() for x in os.environ.get("MATRIX_OIDC_SCOPES", "openid,profile,email").split(",") if x.strip()]
          cfg["oidc_providers"] = [
              {
                  "idp_id": "keycloak",
                  "idp_name": "Keycloak",
                  "discover": True,
                  "issuer": os.environ["MATRIX_OIDC_ISSUER_URL"],
                  "client_id": os.environ["MATRIX_OIDC_CLIENT_ID"],
                  "client_secret": os.environ["MATRIX_OIDC_CLIENT_SECRET"],
                  "scopes": scopes,
                  "user_mapping_provider": {
                      "config": {
                          "localpart_template": "{{ user.preferred_username }}",
                          "display_name_template": "{{ user.name }}"
                      }
                  },
              }
          ]
      else:
          cfg.pop("oidc_providers", None)

      with open(config_path, "w", encoding="utf-8") as f:
          yaml.safe_dump(cfg, f, sort_keys=False)
    PY

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

resource "kubernetes_persistent_volume_claim" "synapse_data" {
  metadata {
    name      = "synapse-data"
    namespace = kubernetes_namespace.matrix.metadata[0].name
    labels    = var.tags
  }

  # local-path uses WaitForFirstConsumer, so binding happens only after a pod mounts the claim.
  # Do not block Terraform on Bound here, otherwise Synapse deployment creation can be delayed.
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

resource "kubernetes_deployment" "synapse" {
  metadata {
    name      = var.name
    namespace = kubernetes_namespace.matrix.metadata[0].name
    labels = merge(var.tags, {
      app = "matrix-synapse"
    })
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "matrix-synapse"
      }
    }

    template {
      metadata {
        labels = {
          app = "matrix-synapse"
        }
      }

      spec {
        automount_service_account_token = false

        container {
          name              = "synapse"
          image             = var.image
          image_pull_policy = "IfNotPresent"

          command = ["/bin/sh", "/bootstrap/start.sh"]

          env {
            name  = "SYNAPSE_SERVER_NAME"
            value = var.server_name
          }

          env {
            name  = "SYNAPSE_REPORT_STATS"
            value = var.report_stats ? "yes" : "no"
          }

          env {
            name  = "MATRIX_PUBLIC_BASEURL"
            value = trimspace(var.public_base_url) != "" ? trimspace(var.public_base_url) : "https://${var.ingress_host}"
          }

          env {
            name = "MATRIX_REGISTRATION_SHARED_SECRET"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.synapse_secrets.metadata[0].name
                key  = "registrationSharedSecret"
              }
            }
          }

          env {
            name  = "MATRIX_OIDC_ENABLED"
            value = var.oidc_enabled ? "true" : "false"
          }

          env {
            name  = "MATRIX_OIDC_ISSUER_URL"
            value = var.oidc_issuer_url
          }

          env {
            name  = "MATRIX_OIDC_CLIENT_ID"
            value = var.oidc_client_id
          }

          env {
            name = "MATRIX_OIDC_CLIENT_SECRET"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.synapse_secrets.metadata[0].name
                key  = "oidcClientSecret"
              }
            }
          }

          env {
            name  = "MATRIX_OIDC_SCOPES"
            value = local.oidc_scopes_value
          }

          env {
            name  = "MATRIX_FEDERATION_ENABLED"
            value = var.federation_enabled ? "true" : "false"
          }

          env {
            name  = "MATRIX_FEDERATION_DOMAIN_WHITELIST"
            value = local.federation_whitelist_value
          }

          port {
            name           = "http"
            container_port = 8008
            protocol       = "TCP"
          }

          volume_mount {
            name       = "synapse-data"
            mount_path = "/data"
          }

          volume_mount {
            name       = "bootstrap"
            mount_path = "/bootstrap"
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
            initial_delay_seconds = 60
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
            initial_delay_seconds = 25
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 6
          }
        }

        volume {
          name = "synapse-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.synapse_data.metadata[0].name
          }
        }

        volume {
          name = "bootstrap"
          config_map {
            name = kubernetes_config_map_v1.bootstrap_scripts.metadata[0].name
          }
        }

        volume {
          name = "oidc-ca"
          secret {
            secret_name = kubernetes_secret_v1.synapse_oidc_ca.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_secret_v1.synapse_secrets,
    kubernetes_secret_v1.synapse_oidc_ca,
    kubernetes_config_map_v1.bootstrap_scripts,
    kubernetes_persistent_volume_claim.synapse_data,
  ]
}

resource "kubernetes_service" "synapse" {
  metadata {
    name      = var.name
    namespace = kubernetes_namespace.matrix.metadata[0].name
    labels = merge(var.tags, {
      app = "matrix-synapse"
    })
  }

  spec {
    selector = {
      app = "matrix-synapse"
    }

    port {
      name        = "http"
      port        = 8008
      target_port = 8008
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }

  depends_on = [kubernetes_deployment.synapse]
}

resource "kubernetes_network_policy" "synapse_oidc_egress" {
  count = var.oidc_enabled ? 1 : 0

  metadata {
    name      = "matrix-synapse-allow-oidc-egress"
    namespace = kubernetes_namespace.matrix.metadata[0].name
    labels    = var.tags
  }

  spec {
    pod_selector {
      match_labels = {
        app = "matrix-synapse"
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

resource "kubernetes_job_v1" "bootstrap_admin" {
  count = var.bootstrap_admin_enabled ? 1 : 0

  metadata {
    name      = "matrix-bootstrap-admin"
    namespace = kubernetes_namespace.matrix.metadata[0].name
    labels    = var.tags
  }

  wait_for_completion = false

  spec {
    backoff_limit = 3

    template {
      metadata {
        labels = {
          app = "matrix-bootstrap-admin"
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
              for i in $(seq 1 90); do
                if python - <<'PY'
import sys
import urllib.request

url = "http://${var.name}:8008/_matrix/client/versions"
try:
    with urllib.request.urlopen(url, timeout=2) as response:
        sys.exit(0 if response.status == 200 else 1)
except Exception:
    sys.exit(1)
PY
                then
                  break
                fi
                sleep 2
              done

              if command -v register_new_matrix_user >/dev/null 2>&1; then
                register_new_matrix_user \
                  -u "$${MATRIX_BOOTSTRAP_ADMIN_USERNAME}" \
                  -p "$${MATRIX_BOOTSTRAP_ADMIN_PASSWORD}" \
                  -a \
                  -k "$${MATRIX_REGISTRATION_SHARED_SECRET}" \
                  http://${var.name}:8008 || true
              else
                python -m synapse._scripts.register_new_matrix_user \
                  -u "$${MATRIX_BOOTSTRAP_ADMIN_USERNAME}" \
                  -p "$${MATRIX_BOOTSTRAP_ADMIN_PASSWORD}" \
                  -a \
                  -k "$${MATRIX_REGISTRATION_SHARED_SECRET}" \
                  http://${var.name}:8008 || true
              fi
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
                name = kubernetes_secret_v1.synapse_secrets.metadata[0].name
                key  = "bootstrapAdminPassword"
              }
            }
          }

          env {
            name = "MATRIX_REGISTRATION_SHARED_SECRET"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.synapse_secrets.metadata[0].name
                key  = "registrationSharedSecret"
              }
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_service.synapse]
}

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
            name = kubernetes_config_map_v1.bootstrap_scripts.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [kubernetes_config_map_v1.bootstrap_scripts]
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

resource "kubernetes_ingress_v1" "synapse" {
  metadata {
    name      = "matrix-synapse"
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
      secret_name = "matrix-synapse-tls"
    }

    rule {
      host = var.ingress_host
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.synapse.metadata[0].name
              port {
                number = 8008
              }
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_service.synapse]
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
