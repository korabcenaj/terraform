locals {
  grafana_oidc_values = var.grafana_oidc_enabled ? yamlencode({
    grafana = {
      "grafana.ini" = {
        server = {
          root_url = "https://${var.grafana_host}"
        }
        auth = {
          disable_login_form = false
        }
        "auth.generic_oauth" = {
          enabled              = true
          name                 = var.grafana_oidc_name
          allow_sign_up        = true
          client_id            = var.grafana_oidc_client_id
          client_secret        = var.grafana_oidc_client_secret
          scopes               = join(" ", var.grafana_oidc_scopes)
          auth_url             = "${var.grafana_oidc_issuer_url}/protocol/openid-connect/auth"
          token_url            = "${var.grafana_oidc_issuer_url}/protocol/openid-connect/token"
          api_url              = "${var.grafana_oidc_issuer_url}/protocol/openid-connect/userinfo"
          login_attribute_path = "sub"
          use_pkce             = true
          use_refresh_token    = true
        }
      }
    }
  }) : ""

  alertmanager_webhook_values = trimspace(var.alertmanager_incident_webhook_url) != "" ? yamlencode({
    alertmanager = {
      config = {
        global = {
          resolve_timeout = "5m"
        }
        route = {
          receiver        = "default-null"
          group_by        = ["alertname", "namespace", "service"]
          group_wait      = "30s"
          group_interval  = "5m"
          repeat_interval = "3h"
          routes = [
            {
              receiver = "incident-webhook"
              matchers = ["severity = \"${var.alertmanager_incident_minimum_severity}\""]
            }
          ]
        }
        receivers = [
          {
            name = "default-null"
          },
          {
            name = "incident-webhook"
            webhook_configs = [
              {
                url           = var.alertmanager_incident_webhook_url
                send_resolved = var.alertmanager_incident_send_resolved
              }
            ]
          }
        ]
      }
    }
  }) : ""
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.namespace
    labels = merge(var.tags, {
      name                                 = var.namespace
      "pod-security.kubernetes.io/enforce" = "privileged"
    })
  }
}

resource "helm_release" "kube_prometheus_stack" {
  name       = var.release_name
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.chart_version
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  values     = compact([local.grafana_oidc_values, local.alertmanager_webhook_values])

  # Increase timeout — this chart installs many CRDs and resources
  wait    = true
  timeout = 600

  # Install/upgrade CRDs
  set {
    name  = "crds.enabled"
    value = "true"
  }

  # ----- Grafana -----
  set {
    name  = "grafana.enabled"
    value = "true"
  }

  set {
    name  = "grafana.adminPassword"
    value = var.grafana_admin_password
  }

  set {
    name  = "grafana.assertNoLeakedSecrets"
    value = "false"
  }

  # Some CSI/NFS backends deny recursive chown; avoid blocking startup.
  set {
    name  = "grafana.initChownData.enabled"
    value = "false"
  }

  set {
    name  = "grafana.persistence.enabled"
    value = "true"
  }

  set {
    name  = "grafana.persistence.storageClassName"
    value = var.grafana_storage_class
  }

  set {
    name  = "grafana.persistence.size"
    value = var.grafana_storage_size
  }

  # Ingress handled separately (via existing monitoring module)
  set {
    name  = "grafana.ingress.enabled"
    value = "false"
  }

  # ----- Prometheus -----
  set {
    name  = "prometheus.prometheusSpec.retention"
    value = var.prometheus_retention
  }

  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName"
    value = var.prometheus_storage_class
  }

  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage"
    value = var.prometheus_storage_size
  }

  # Ingress handled separately (via existing monitoring module)
  set {
    name  = "prometheus.ingress.enabled"
    value = "false"
  }

  # ----- Alertmanager -----
  set {
    name  = "alertmanager.enabled"
    value = "true"
  }

  # ----- Node Exporter -----
  set {
    name  = "nodeExporter.enabled"
    value = "true"
  }

  # ----- kube-state-metrics -----
  set {
    name  = "kubeStateMetrics.enabled"
    value = "true"
  }
}
