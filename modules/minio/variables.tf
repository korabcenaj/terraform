variable "namespace" {
  description = "Namespace where MinIO will be installed"
  type        = string
  default     = "minio"
}

variable "release_name" {
  description = "Helm release name for MinIO"
  type        = string
  default     = "minio"
}

variable "chart_version" {
  description = "MinIO Helm chart version"
  type        = string
  default     = "5.4.0"
}

variable "root_user" {
  description = "MinIO root username"
  type        = string
}

variable "root_password" {
  description = "MinIO root password"
  type        = string
  sensitive   = true
}

variable "storage_size" {
  description = "Persistent volume size for MinIO"
  type        = string
  default     = "50Gi"
}

variable "storage_class" {
  description = "Storage class for MinIO persistence"
  type        = string
  default     = "local-path"
}

variable "ingress_host" {
  description = "Hostname for MinIO console ingress (e.g. minio.local.lan)"
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