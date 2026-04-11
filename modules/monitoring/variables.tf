variable "tags" {
  description = "Tags for resources"
  type        = map(string)
  default     = {}
}

variable "grafana_service_name" {
  description = "Name of the existing Grafana service"
  type        = string
  default     = "monitor-grafana"
}

variable "grafana_service_port" {
  description = "Port of the Grafana service"
  type        = number
  default     = 80
}

variable "prometheus_service_name" {
  description = "Name of the existing Prometheus service"
  type        = string
  default     = "monitor-kube-prometheus-st-prometheus"
}

variable "prometheus_service_port" {
  description = "Port of the Prometheus service"
  type        = number
  default     = 9090
}
