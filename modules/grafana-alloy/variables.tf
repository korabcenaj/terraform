variable "release_name" {
  description = "Helm release name for Grafana k8s-monitoring"
  type        = string
  default     = "grafana-k8s-monitoring"
}

variable "chart_version" {
  description = "k8s-monitoring Helm chart version"
  type        = string
  default     = "4.1.3"
}

variable "cluster_name" {
  description = "Kubernetes cluster name for Grafana Cloud"
  type        = string
  default     = "homelab"
}

# ---------------------------------------------------------------------------
# Grafana Cloud destination credentials
# ---------------------------------------------------------------------------

variable "metrics_destination_name" {
  description = "Name of the Grafana Cloud metrics (Prometheus) destination"
  type        = string
  default     = "grafana-cloud-metrics"
}

variable "metrics_destination_url" {
  description = "Grafana Cloud Prometheus push URL"
  type        = string
  default     = "https://prometheus-prod-65-prod-eu-west-2.grafana.net./api/prom/push"
}

variable "metrics_destination_username" {
  description = "Grafana Cloud metrics instance ID"
  type        = string
  default     = "3260816"
}

variable "metrics_destination_password" {
  description = "Grafana Cloud metrics API key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "logs_destination_name" {
  description = "Name of the Grafana Cloud logs (Loki) destination"
  type        = string
  default     = "grafana-cloud-logs"
}

variable "logs_destination_url" {
  description = "Grafana Cloud Loki push URL"
  type        = string
  default     = "https://logs-prod-012.grafana.net./loki/api/v1/push"
}

variable "logs_destination_username" {
  description = "Grafana Cloud logs instance ID"
  type        = string
  default     = "1626083"
}

variable "logs_destination_password" {
  description = "Grafana Cloud logs API key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "opencost_prometheus_url" {
  description = "External Prometheus URL for OpenCost metrics source"
  type        = string
  default     = "https://prometheus-prod-65-prod-eu-west-2.grafana.net./api/prom"
}

# ---------------------------------------------------------------------------
# Alloy collector configuration
# ---------------------------------------------------------------------------

variable "alloy_metrics_presets" {
  description = "Alloy presets for the metrics collector"
  type        = list(string)
  default     = ["clustered", "statefulset"]
}

variable "alloy_singleton_presets" {
  description = "Alloy presets for the singleton collector"
  type        = list(string)
  default     = ["singleton"]
}

variable "alloy_logs_presets" {
  description = "Alloy presets for the logs collector"
  type        = list(string)
  default     = ["filesystem-log-reader", "daemonset"]
}

variable "alloy_cpu_request" {
  description = "CPU request for Alloy collectors"
  type        = string
  default     = "50m"
}

variable "alloy_memory_request" {
  description = "Memory request for Alloy collectors"
  type        = string
  default     = "128Mi"
}

variable "alloy_cpu_limit" {
  description = "CPU limit for Alloy collectors"
  type        = string
  default     = "500m"
}

variable "alloy_memory_limit" {
  description = "Memory limit for Alloy collectors"
  type        = string
  default     = "512Mi"
}

variable "tags" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}
