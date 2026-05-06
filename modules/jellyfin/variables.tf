variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
}

variable "replicas" {
  description = "Number of replicas"
  type        = number
  default     = 1
}

variable "storage_class" {
  description = "Storage class for volumes"
  type        = string
  default     = "local-path"
}

variable "config_size" {
  description = "Config volume size"
  type        = string
  default     = "20Gi"
}

variable "cache_size" {
  description = "Cache volume size"
  type        = string
  default     = "5Gi"
}

variable "cpu_request" {
  description = "CPU request"
  type        = string
  default     = "250m"
}

variable "memory_request" {
  description = "Memory request"
  type        = string
  default     = "512Mi"
}

variable "cpu_limit" {
  description = "CPU limit"
  type        = string
  default     = "1000m"
}

variable "memory_limit" {
  description = "Memory limit"
  type        = string
  default     = "1Gi"
}

variable "tags" {
  description = "Tags for resources"
  type        = map(string)
  default     = {}
}

variable "node_name" {
  description = "Node name to pin Jellyfin scheduling (uses kubernetes.io/hostname selector)"
  type        = string
}

variable "media_path" {
  description = "Host path for media files, mounted read-only at /media"
  type        = string
}

variable "ingress_host" {
  description = "Hostname used by the Jellyfin ingress"
  type        = string
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
