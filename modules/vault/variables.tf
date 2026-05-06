variable "namespace" {
  description = "Namespace where Vault will be installed"
  type        = string
  default     = "vault"
}

variable "release_name" {
  description = "Helm release name for Vault"
  type        = string
  default     = "vault"
}

variable "chart_version" {
  description = "Vault Helm chart version"
  type        = string
  default     = "0.28.1"
}

variable "storage_size" {
  description = "Persistent volume size for Vault data"
  type        = string
  default     = "10Gi"
}

variable "storage_class" {
  description = "Storage class for Vault persistent volume"
  type        = string
  default     = "local-path"
}

variable "ingress_host" {
  description = "Hostname for Vault UI ingress (e.g. vault.local.lan)"
  type        = string
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