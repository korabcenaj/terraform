variable "namespace" {
  description = "Namespace where ingress-nginx will be installed"
  type        = string
  default     = "ingress-nginx"
}

variable "release_name" {
  description = "Helm release name for ingress-nginx"
  type        = string
  default     = "ingress-nginx"
}

variable "chart_version" {
  description = "ingress-nginx Helm chart version"
  type        = string
  default     = "4.12.1"
}

variable "service_type" {
  description = "Service type for the ingress controller (LoadBalancer or NodePort)"
  type        = string
  default     = "LoadBalancer"

  validation {
    condition     = contains(["LoadBalancer", "NodePort", "ClusterIP"], var.service_type)
    error_message = "service_type must be LoadBalancer, NodePort, or ClusterIP."
  }
}

variable "replica_count" {
  description = "Number of ingress-nginx controller replicas"
  type        = number
  default     = 1
}

variable "enable_metrics" {
  description = "Expose Prometheus metrics endpoint on the controller"
  type        = bool
  default     = true
}

variable "limit_rps" {
  description = "Global request rate limit per client IP (0 disables)"
  type        = number
  default     = 0
}

variable "limit_connections" {
  description = "Global concurrent connection limit per client IP (0 disables)"
  type        = number
  default     = 0
}

variable "enable_modsecurity" {
  description = "Enable ModSecurity support in ingress-nginx"
  type        = bool
  default     = false
}

variable "enable_owasp_crs" {
  description = "Enable OWASP CRS with ModSecurity"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}
