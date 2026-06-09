variable "tags" {
  description = "Tags for resources"
  type        = map(string)
  default     = {}
}

variable "grafana_service_name" {
  description = "Name of the existing Grafana service"
  type        = string
  default     = "monitoring-grafana"
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
