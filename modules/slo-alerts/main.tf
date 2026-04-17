resource "kubernetes_manifest" "portfolio_slo_prometheus_rule" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PrometheusRule"
    metadata = {
      name      = var.rule_name
      namespace = var.namespace
      labels = merge(var.tags, {
        app     = "portfolio"
        release = var.prometheus_release_label
      })
    }
    spec = {
      groups = [
        {
          name = "portfolio-slo.rules"
          rules = [
            {
              alert = "PortfolioAvailabilityBurnRateHigh"
              expr  = "(sum(rate(nginx_ingress_controller_requests{host=\"${var.portfolio_host}\",status=~\"5..\"}[5m])) / sum(rate(nginx_ingress_controller_requests{host=\"${var.portfolio_host}\"}[5m]))) > ${1 - (var.availability_target_percent / 100)}"
              for   = "10m"
              labels = {
                severity = "critical"
                service  = "portfolio"
                slo      = "availability"
              }
              annotations = {
                summary     = "Portfolio error budget burn rate is too high"
                description = "5xx ratio exceeded the SLO threshold for portfolio on host ${var.portfolio_host}."
              }
            },
            {
              alert = "PortfolioLatencyP95High"
              expr  = "histogram_quantile(0.95, sum(rate(nginx_ingress_controller_request_duration_seconds_bucket{host=\"${var.portfolio_host}\"}[5m])) by (le)) > ${var.latency_p95_seconds}"
              for   = "15m"
              labels = {
                severity = "warning"
                service  = "portfolio"
                slo      = "latency"
              }
              annotations = {
                summary     = "Portfolio p95 latency is above target"
                description = "Portfolio p95 latency has been above ${var.latency_p95_seconds}s for at least 15 minutes."
              }
            }
          ]
        }
      ]
    }
  }
}
