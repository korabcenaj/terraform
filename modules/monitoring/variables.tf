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

variable "grafana_host" {
  description = "Hostname for the Grafana ingress"
  type        = string
  default     = "grafana.local.lan"
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

variable "prometheus_host" {
  description = "Hostname for the Prometheus ingress"
  type        = string
  default     = "prometheus.local.lan"
}
