variable "namespace" {
  description = "Namespace where the AnalysisTemplate is created"
  type        = string
  default     = "portfolio"
}

variable "template_name" {
  description = "AnalysisTemplate resource name"
  type        = string
  default     = "portfolio-rollout-metrics"
}

variable "portfolio_host" {
  description = "Portfolio ingress host used in ingress-nginx metric queries"
  type        = string
}

variable "prometheus_address" {
  description = "Prometheus base URL reachable from the rollout controller"
  type        = string
  default     = "http://monitor-kube-prometheus-st-prometheus.monitoring.svc.cluster.local:9090"
}

variable "success_rate_minimum_percent" {
  description = "Minimum acceptable request success rate percentage"
  type        = number
  default     = 99
}

variable "latency_p95_threshold_seconds" {
  description = "Maximum acceptable p95 latency in seconds"
  type        = number
  default     = 1
}

variable "tags" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}
