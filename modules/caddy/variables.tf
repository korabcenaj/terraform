variable "namespace" {
  description = "Namespace where the Caddy Ingress Controller will be installed"
  type        = string
  default     = "caddy-system"
}

variable "release_name" {
  description = "Helm release name for the Caddy Ingress Controller"
  type        = string
  default     = "caddy"
}

variable "chart_version" {
  description = "Caddy Ingress Controller Helm chart version"
  type        = string
  default     = "1.1.0"
}

variable "ingress_class_name" {
  description = "IngressClass name registered by this Caddy controller"
  type        = string
  default     = "caddy"
}

variable "default_ingress_class" {
  description = "Set Caddy as the cluster-default IngressClass"
  type        = bool
  default     = false
}

variable "service_type" {
  description = "Service type for the Caddy controller (LoadBalancer, NodePort, or ClusterIP)"
  type        = string
  default     = "LoadBalancer"

  validation {
    condition     = contains(["LoadBalancer", "NodePort", "ClusterIP"], var.service_type)
    error_message = "service_type must be LoadBalancer, NodePort, or ClusterIP."
  }
}

variable "replica_count" {
  description = "Number of Caddy Ingress Controller replicas"
  type        = number
  default     = 1

  validation {
    condition     = var.replica_count >= 1
    error_message = "replica_count must be at least 1."
  }
}

variable "acme_ca_server" {
  description = "ACME CA server URL for automatic TLS certificate provisioning. Leave empty to disable."
  type        = string
  default     = ""
}

variable "acme_email" {
  description = "Email address registered with the ACME CA (required when acme_ca_server is set)"
  type        = string
  default     = ""
}

variable "on_demand_tls" {
  description = "Enable Caddy's on-demand TLS (obtains certs lazily on first request)"
  type        = bool
  default     = false
}

variable "enable_metrics" {
  description = "Expose a Prometheus /metrics endpoint on the Caddy controller"
  type        = bool
  default     = true
}

variable "debug" {
  description = "Enable Caddy debug logging"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Labels applied to all managed resources"
  type        = map(string)
  default     = {}
}
