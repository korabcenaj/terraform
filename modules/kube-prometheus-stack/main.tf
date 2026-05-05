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

  # Alertmanager configuration — embedded as a Helm value so Terraform owns it
  alertmanager_values = var.alertmanager_enabled && var.alertmanager_webhook_url != "" ? yamlencode({
    alertmanager = {
      config = {
        global = {
          resolve_timeout = "5m"
        }
        route = {
          group_by        = ["alertname", "namespace", "severity"]
          group_wait      = "30s"
          group_interval  = "5m"
          repeat_interval = var.alertmanager_repeat_interval
          receiver        = "default"
          routes = [
            {
              matchers = ["severity = critical"]
              receiver = "default"
              continue = false
            }
          ]
        }
        receivers = [
          {
            name = "default"
            webhook_configs = [
              {
                url           = var.alertmanager_webhook_url
                send_resolved = true
                http_config   = {}
              }
            ]
          }
        ]
        inhibit_rules = [
          {
            source_matchers = ["severity = critical"]
            target_matchers = ["severity = warning"]
            equal           = ["alertname", "namespace"]
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
  values     = compact([local.grafana_oidc_values, local.alertmanager_values])

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

  set_sensitive {
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

# ---------------------------------------------------------------------------
# Critical PrometheusRule — baseline alerts for a homelab cluster
# ---------------------------------------------------------------------------

resource "kubernetes_manifest" "critical_alerts" {
  count = var.create_alert_rules ? 1 : 0

  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PrometheusRule"
    metadata = {
      name      = "homelab-critical-alerts"
      namespace = kubernetes_namespace.monitoring.metadata[0].name
      labels = merge(var.tags, {
        # kube-prometheus-stack selects rules by this label pair
        "app"     = "kube-prometheus-stack"
        "release" = var.release_name
      })
    }
    spec = {
      groups = [
        {
          name = "node"
          rules = [
            {
              alert  = "NodeDown"
              expr   = "up{job=\"node-exporter\"} == 0"
              for    = "2m"
              labels = { severity = "critical" }
              annotations = {
                summary     = "Node {{ $labels.instance }} is down"
                description = "node-exporter on {{ $labels.instance }} has been unreachable for more than 2 minutes."
              }
            },
            {
              alert  = "NodeDiskPressure"
              expr   = "kubelet_node_name{condition=\"DiskPressure\"} == 1"
              for    = "1m"
              labels = { severity = "critical" }
              annotations = {
                summary     = "Node {{ $labels.node }} has disk pressure"
                description = "The node is reporting DiskPressure. Check available disk space."
              }
            },
            {
              alert  = "NodeFilesystemAlmostFull"
              expr   = "(node_filesystem_avail_bytes{fstype!~\"tmpfs|fuse.lxcfs\"} / node_filesystem_size_bytes{fstype!~\"tmpfs|fuse.lxcfs\"}) < 0.10"
              for    = "5m"
              labels = { severity = "warning" }
              annotations = {
                summary     = "Filesystem on {{ $labels.instance }}:{{ $labels.mountpoint }} < 10% free"
                description = "Only {{ $value | humanizePercentage }} of disk space remains on {{ $labels.mountpoint }}."
              }
            },
            {
              alert  = "NodeHighMemoryUsage"
              expr   = "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) > 0.90"
              for    = "5m"
              labels = { severity = "warning" }
              annotations = {
                summary     = "Node {{ $labels.instance }} memory > 90%"
                description = "Node memory usage has been above 90% for 5 minutes."
              }
            },
          ]
        },
        {
          name = "workload"
          rules = [
            {
              alert  = "PodCrashLooping"
              expr   = "increase(kube_pod_container_status_restarts_total[15m]) > 3"
              for    = "1m"
              labels = { severity = "critical" }
              annotations = {
                summary     = "Pod {{ $labels.namespace }}/{{ $labels.pod }} is crash-looping"
                description = "Container {{ $labels.container }} has restarted {{ $value }} times in the last 15 minutes."
              }
            },
            {
              alert  = "PodOOMKilled"
              expr   = "kube_pod_container_status_last_terminated_reason{reason=\"OOMKilled\"} == 1"
              for    = "0m"
              labels = { severity = "warning" }
              annotations = {
                summary     = "Pod {{ $labels.namespace }}/{{ $labels.pod }} was OOMKilled"
                description = "Container {{ $labels.container }} was terminated due to out-of-memory."
              }
            },
            {
              alert  = "PodNotReady"
              expr   = "kube_pod_status_ready{condition=\"false\"} == 1"
              for    = "10m"
              labels = { severity = "warning" }
              annotations = {
                summary     = "Pod {{ $labels.namespace }}/{{ $labels.pod }} not ready"
                description = "Pod has been in a non-ready state for more than 10 minutes."
              }
            },
          ]
        },
        {
          name = "backup"
          rules = [
            {
              alert  = "VeleroBackupFailed"
              expr   = "velero_backup_failure_total > 0"
              for    = "0m"
              labels = { severity = "critical" }
              annotations = {
                summary     = "Velero backup failed"
                description = "A Velero backup has failed. Check the Velero logs for details."
              }
            },
            {
              alert  = "VeleroBackupPartiallyFailed"
              expr   = "velero_backup_partial_failure_total > 0"
              for    = "0m"
              labels = { severity = "warning" }
              annotations = {
                summary     = "Velero backup partially failed"
                description = "A Velero backup completed with partial failures."
              }
            },
          ]
        },
      ]
    }
  }

  depends_on = [helm_release.kube_prometheus_stack]
}
