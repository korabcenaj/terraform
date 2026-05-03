variable "namespace" {
  type        = string
  default     = "monitoring"
  description = "Namespace to deploy Pushgateway into (co-located with Prometheus by default)."
}

variable "release_name" {
  type        = string
  default     = "pushgateway"
  description = "Helm release name."
}

variable "chart_version" {
  type        = string
  default     = "3.6.0"
  description = "prometheus-pushgateway Helm chart version."
}

variable "enable_service_monitor" {
  type        = bool
  default     = true
  description = "Create a ServiceMonitor so Prometheus auto-scrapes Pushgateway."
}

variable "persistence_enabled" {
  type        = bool
  default     = false
  description = "Enable PVC persistence for push data."
}

variable "extra_values" {
  type        = map(string)
  default     = {}
  description = "Additional Helm values to pass as set blocks."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Labels applied to created resources (informational)."
}
