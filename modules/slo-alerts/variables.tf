variable "namespace" {
  description = "Namespace where PrometheusRule resources are created"
  type        = string
  default     = "monitoring"
}

variable "rule_name" {
  description = "PrometheusRule resource name"
  type        = string
  default     = "portfolio-slo-alerts"
}

variable "portfolio_host" {
  description = "Portfolio ingress host used in ingress-nginx metric filters"
  type        = string
}

variable "availability_target_percent" {
  description = "Availability SLO target percent (e.g. 99 means 1% error budget)"
  type        = number
  default     = 99

  validation {
    condition     = var.availability_target_percent > 0 && var.availability_target_percent < 100
    error_message = "availability_target_percent must be > 0 and < 100."
  }
}

variable "latency_p95_seconds" {
  description = "p95 latency threshold in seconds"
  type        = number
  default     = 1

  validation {
    condition     = var.latency_p95_seconds > 0
    error_message = "latency_p95_seconds must be > 0."
  }
}

variable "prometheus_release_label" {
  description = "Prometheus release selector label value used by kube-prometheus-stack"
  type        = string
  default     = "monitor"
}

variable "tags" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}
