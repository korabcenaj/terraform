resource "kubernetes_manifest" "portfolio_analysis_template" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "AnalysisTemplate"
    metadata = {
      name      = var.template_name
      namespace = var.namespace
      labels = merge(var.tags, {
        app = "portfolio"
      })
    }
    spec = {
      metrics = [
        {
          name             = "success-rate"
          interval         = "1m"
          successCondition = "result[0] >= ${var.success_rate_minimum_percent}"
          failureLimit     = 2
          provider = {
            prometheus = {
              address = var.prometheus_address
              query   = "100 * (1 - (sum(rate(nginx_ingress_controller_requests{host=\"${var.portfolio_host}\",status=~\"5..\"}[2m])) / clamp_min(sum(rate(nginx_ingress_controller_requests{host=\"${var.portfolio_host}\"}[2m])), 1)))"
            }
          }
        },
        {
          name             = "latency-p95"
          interval         = "1m"
          successCondition = "result[0] <= ${var.latency_p95_threshold_seconds}"
          failureLimit     = 2
          provider = {
            prometheus = {
              address = var.prometheus_address
              query   = "histogram_quantile(0.95, sum(rate(nginx_ingress_controller_request_duration_seconds_bucket{host=\"${var.portfolio_host}\"}[2m])) by (le))"
            }
          }
        }
      ]
    }
  }
}
