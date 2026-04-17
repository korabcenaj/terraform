variable "namespace" {
  description = "Namespace where kube-prometheus-stack will be installed"
  type        = string
  default     = "monitoring"
}

variable "release_name" {
  description = "Helm release name — must match the prefix used in existing service names (e.g. monitor-grafana)"
  type        = string
  default     = "monitor"
}

variable "chart_version" {
  description = "kube-prometheus-stack Helm chart version"
  type        = string
  default     = "70.4.0"
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
}

variable "grafana_host" {
  description = "Hostname for the Grafana ingress"
  type        = string
  default     = "grafana.local.lan"
}

variable "prometheus_host" {
  description = "Hostname for the Prometheus ingress"
  type        = string
  default     = "prometheus.local.lan"
}

variable "prometheus_retention" {
  description = "Prometheus data retention period"
  type        = string
  default     = "30d"
}

variable "prometheus_storage_size" {
  description = "Prometheus persistent volume size"
  type        = string
  default     = "20Gi"
}

variable "prometheus_storage_class" {
  description = "Storage class for Prometheus persistent volume"
  type        = string
  default     = "local-path"
}

variable "grafana_storage_size" {
  description = "Grafana persistent volume size"
  type        = string
  default     = "2Gi"
}

variable "grafana_storage_class" {
  description = "Storage class for Grafana persistent volume"
  type        = string
  default     = "local-path"
}

variable "grafana_oidc_enabled" {
  description = "Enable native OIDC login for Grafana"
  type        = bool
  default     = false
}

variable "grafana_oidc_name" {
  description = "Display name for the OIDC provider in Grafana"
  type        = string
  default     = "Keycloak"
}

variable "grafana_oidc_issuer_url" {
  description = "OIDC issuer URL used by Grafana"
  type        = string
  default     = ""
}

variable "grafana_oidc_client_id" {
  description = "OIDC client ID for Grafana"
  type        = string
  sensitive   = true
  default     = ""
}

variable "grafana_oidc_client_secret" {
  description = "OIDC client secret for Grafana"
  type        = string
  sensitive   = true
  default     = ""
}

variable "grafana_oidc_scopes" {
  description = "OIDC scopes requested by Grafana"
  type        = list(string)
  default     = ["openid", "profile", "email"]
}

variable "alertmanager_incident_webhook_url" {
  description = "Optional webhook URL for routing selected Alertmanager notifications"
  type        = string
  sensitive   = true
  default     = ""
}

variable "alertmanager_incident_minimum_severity" {
  description = "Alert severity matcher routed to incident webhook"
  type        = string
  default     = "critical"
}

variable "alertmanager_incident_send_resolved" {
  description = "Whether to send resolved notifications to the incident webhook"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}
