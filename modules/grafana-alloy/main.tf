# Grafana Alloy k8s-monitoring via Helm
# NOTE: The k8s-monitoring Helm chart REQUIRES inline credentials for
# destinations. The chart creates its own Secrets from these values automatically.
# For production security, migrate to External Secrets Operator or ArgoCD Vault Plugin.

resource "kubernetes_namespace" "grafana_alloy" {
  metadata {
    name = "grafana-alloy"
    labels = merge(var.tags, {
      name = "grafana-alloy"
    })
  }

  lifecycle {
    ignore_changes = [metadata[0].annotations]
  }
}

resource "helm_release" "grafana_k8s_monitoring" {
  name       = var.release_name
  repository = "https://grafana.github.io/helm-charts"
  chart      = "k8s-monitoring"
  version    = var.chart_version
  namespace  = kubernetes_namespace.grafana_alloy.metadata[0].name

  values = [
    yamlencode({
      cluster = {
        name = var.cluster_name
      }

      destinations = {
        (var.metrics_destination_name) = {
          type = "prometheus"
          url  = var.metrics_destination_url
          auth = {
            type     = "basic"
            username = var.metrics_destination_username
            password = var.metrics_destination_password
          }
        }
        (var.logs_destination_name) = {
          type = "loki"
          url  = var.logs_destination_url
          auth = {
            type     = "basic"
            username = var.logs_destination_username
            password = var.logs_destination_password
          }
        }
      }

      clusterMetrics = {
        enabled   = true
        collector = "alloy-metrics"
      }

      hostMetrics = {
        enabled   = true
        collector = "alloy-metrics"
        linuxHosts = {
          enabled = true
        }
        windowsHosts = {
          enabled = false
        }
        energyMetrics = {
          enabled = true
        }
      }

      costMetrics = {
        enabled   = true
        collector = "alloy-metrics"
      }

      clusterEvents = {
        enabled   = true
        collector = "alloy-singleton"
      }

      podLogsViaLoki = {
        enabled   = true
        collector = "alloy-logs"
      }

      collectors = {
        "alloy-metrics" = {
          presets = var.alloy_metrics_presets
        }
        "alloy-singleton" = {
          presets = var.alloy_singleton_presets
        }
        "alloy-logs" = {
          presets = var.alloy_logs_presets
        }
      }

      collectorCommon = {
        alloy = {
          resources = {
            requests = {
              cpu    = var.alloy_cpu_request
              memory = var.alloy_memory_request
            }
            limits = {
              cpu    = var.alloy_cpu_limit
              memory = var.alloy_memory_limit
            }
          }
          securityContext = {
            runAsNonRoot = true
            runAsUser    = 1000
            runAsGroup   = 1000
            fsGroup      = 1000
          }
          remoteConfig = {
            enabled = false
          }
        }
      }

      telemetryServices = {
        "kube-state-metrics" = {
          deploy = true
          "kube-state-metrics" = {
            containerSecurityContext = {
              runAsNonRoot = true
              runAsUser    = 65534
            }
            resources = {
              requests = {
                cpu    = "10m"
                memory = "64Mi"
              }
              limits = {
                cpu    = "200m"
                memory = "256Mi"
              }
            }
          }
        }
        "node-exporter" = {
          deploy = true
          "node-exporter" = {
            containerSecurityContext = {
              runAsNonRoot = true
              runAsUser    = 65534
            }
            resources = {
              requests = {
                cpu    = "10m"
                memory = "32Mi"
              }
              limits = {
                cpu    = "100m"
                memory = "128Mi"
              }
            }
          }
        }
        "windows-exporter" = {
          deploy = false
        }
        opencost = {
          deploy        = true
          metricsSource = var.metrics_destination_name
          opencost = {
            exporter = {
              defaultClusterId = var.cluster_name
              resources = {
                requests = {
                  cpu    = "10m"
                  memory = "64Mi"
                }
                limits = {
                  cpu    = "200m"
                  memory = "256Mi"
                }
              }
              securityContext = {
                runAsNonRoot = true
                runAsUser    = 1000
              }
            }
            prometheus = {
              existingSecretName = "${var.metrics_destination_name}-${var.release_name}"
              external = {
                url = var.opencost_prometheus_url
              }
            }
          }
        }
        kepler = {
          deploy = true
          kepler = {
            containerSecurityContext = {
              runAsNonRoot = true
              runAsUser    = 65534
            }
            resources = {
              requests = {
                cpu    = "100m"
                memory = "128Mi"
              }
              limits = {
                cpu    = "500m"
                memory = "512Mi"
              }
            }
          }
        }
      }
    })
  ]

  wait    = true
  timeout = 600
}
