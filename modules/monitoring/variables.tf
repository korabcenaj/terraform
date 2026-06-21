variable "namespace" {
  description = "Namespace for the monitoring stack"
  type        = string
  default     = "monitoring"
}

variable "tags" {
  description = "Tags for resources"
  type        = map(string)
  default     = {}
}

# --- kube-prometheus-stack Helm chart ---

variable "kps_release_name" {
  description = "Helm release name for kube-prometheus-stack"
  type        = string
  default     = "kps"
}

variable "kps_chart_version" {
  description = "kube-prometheus-stack Helm chart version"
  type        = string
  default     = "86.2.3"
}

variable "kps_timeout" {
  description = "Helm install timeout in seconds"
  type        = number
  default     = 900
}

variable "prometheus_retention" {
  description = "Prometheus data retention period"
  type        = string
  default     = "7d"
}

variable "prometheus_storage_size" {
  description = "Persistent volume size for Prometheus"
  type        = string
  default     = "10Gi"
}

variable "prometheus_cpu_request" {
  description = "CPU request for Prometheus"
  type        = string
  default     = "200m"
}

variable "prometheus_memory_request" {
  description = "Memory request for Prometheus"
  type        = string
  default     = "512Mi"
}

variable "prometheus_cpu_limit" {
  description = "CPU limit for Prometheus"
  type        = string
  default     = "1"
}

variable "prometheus_memory_limit" {
  description = "Memory limit for Prometheus"
  type        = string
  default     = "2Gi"
}

# --- Grafana ingress ---

variable "grafana_service_name" {
  description = "Name of the Grafana service created by kube-prometheus-stack"
  type        = string
  default     = "kps-grafana"
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

variable "oauth2_proxy_url" {
  description = "Public OAuth2 Proxy URL used by ingress auth annotations (e.g. https://auth.local.lan)"
  type        = string
  default     = ""
}

variable "oauth2_proxy_auth_internal_url" {
  description = "In-cluster OAuth2 Proxy URL for NGINX auth-url subrequests (e.g. http://oauth2-proxy.oauth2-proxy.svc.cluster.local:4180)"
  type        = string
  default     = ""
}

variable "oauth2_proxy_middleware" {
  description = "Traefik Middleware annotation for OAuth2 Proxy forward-auth (e.g. oauth2-proxy-forward-auth@kubernetescrd)"
  type        = string
  default     = ""
}
