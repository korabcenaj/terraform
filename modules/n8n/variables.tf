variable "namespace" {
  description = "Namespace where n8n will be installed"
  type        = string
  default     = "n8n"
}

variable "release_name" {
  description = "Helm release name for n8n"
  type        = string
  default     = "n8n"
}

variable "chart_version" {
  description = "n8n Helm chart version (8gears community chart)"
  type        = string
  default     = "0.25.2"
}

variable "encryption_key" {
  description = "Encryption key used by n8n to encrypt stored credentials. Must be stable — changing it invalidates all saved credentials."
  type        = string
  sensitive   = true

  validation {
    condition     = length(trimspace(var.encryption_key)) >= 24
    error_message = "encryption_key must be at least 24 characters long."
  }
}

variable "storage_size" {
  description = "Persistent volume size for n8n data (SQLite database and workflow files)"
  type        = string
  default     = "5Gi"
}

variable "storage_class" {
  description = "Storage class for n8n persistence"
  type        = string
  default     = "local-path"
}

variable "ingress_host" {
  description = "Hostname for the n8n ingress (e.g. n8n.local.lan)"
  type        = string
}

variable "timezone" {
  description = "Timezone for n8n (used for scheduled workflows)"
  type        = string
  default     = "UTC"
}

variable "webhook_url" {
  description = "Public-facing base URL used by n8n for webhooks. Defaults to https://<ingress_host>."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "oauth2_proxy_url" {
  description = "Public OAuth2 Proxy URL (e.g. https://auth.local.lan). If set, forward-auth is enabled on the ingress."
  type        = string
  default     = ""
}

variable "oauth2_proxy_auth_internal_url" {
  description = "In-cluster OAuth2 Proxy URL for NGINX auth-url subrequests (e.g. http://oauth2-proxy.oauth2-proxy.svc.cluster.local)"
  type        = string
  default     = ""
}

variable "oauth2_proxy_middleware" {
  description = "Traefik Middleware annotation for OAuth2 Proxy forward-auth (e.g. oauth2-proxy-forward-auth@kubernetescrd)"
  type        = string
  default     = ""
}
