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
  description = "Host path for media files, mounted read-only at /media (ignored when media_pvc_name is set)"
  type        = string
  default     = "/media/library"
}

variable "media_pvc_name" {
  description = "Name of an existing PVC to use for media (takes precedence over media_path)"
  type        = string
  default     = "jellyfin-media-pvc"
}

variable "image" {
  description = "Jellyfin container image"
  type        = string
  default     = "jellyfin/jellyfin:10.10.7"
}

variable "load_balancer_ip" {
  description = "External IP for the LoadBalancer service (e.g. 192.168.0.209)"
  type        = string
  default     = ""
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

variable "oauth2_proxy_middleware" {
  description = "Traefik Middleware annotation for OAuth2 Proxy forward-auth (e.g. oauth2-proxy-forward-auth@kubernetescrd)"
  type        = string
  default     = ""
}

variable "gpu_count" {
  description = "Number of AMD GPUs to request for hardware transcoding (0 disables GPU)"
  type        = number
  default     = 0
}

variable "gpu_resource_name" {
  description = "Kubernetes resource name for AMD GPU (e.g. amd.com/gpu or gpu.amd.com/amdgpu)"
  type        = string
  default     = "amd.com/gpu"
}
