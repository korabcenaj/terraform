variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
}

variable "image" {
  description = "Container image for the portfolio web app"
  type        = string
  default     = "nginxinc/nginx-unprivileged:1.29-alpine"
}

variable "image_pull_secrets" {
  description = "List of image pull secret names"
  type        = list(string)
  default     = []
}

variable "replicas" {
  description = "Number of replicas (ignored when KEDA is enabled)"
  type        = number
  default     = 0
}

variable "cpu_request" {
  description = "CPU request"
  type        = string
  default     = "100m"
}

variable "memory_request" {
  description = "Memory request"
  type        = string
  default     = "64Mi"
}

variable "cpu_limit" {
  description = "CPU limit"
  type        = string
  default     = "500m"
}

variable "memory_limit" {
  description = "Memory limit"
  type        = string
  default     = "256Mi"
}

variable "ingress_host" {
  description = "Hostname used by the portfolio ingress"
  type        = string
}

variable "tags" {
  description = "Tags for resources"
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

# KEDA idle-scaler configuration
variable "keda_enabled" {
  description = "Enable KEDA cron-based idle scaling (scales to 0 outside active window)"
  type        = bool
  default     = true
}

variable "keda_min_replicas" {
  description = "Minimum replicas when KEDA is active"
  type        = number
  default     = 0
}

variable "keda_max_replicas" {
  description = "Maximum replicas when KEDA is active"
  type        = number
  default     = 3
}

variable "keda_cron_start" {
  description = "Cron expression for scaling up (start of active window)"
  type        = string
  default     = "0 8 * * *"
}

variable "keda_cron_end" {
  description = "Cron expression for scaling down (end of active window)"
  type        = string
  default     = "0 22 * * *"
}

variable "keda_timezone" {
  description = "Timezone for KEDA cron trigger"
  type        = string
  default     = "America/New_York"
}

variable "keda_desired_replicas" {
  description = "Desired replicas during active window"
  type        = string
  default     = "1"
}

variable "configmap_files" {
  description = "Map of filename to file path for the portfolio-static ConfigMap content"
  type        = map(string)
  default     = {}
}
