variable "namespace" {
  description = "Namespace where Keycloak will be installed"
  type        = string
  default     = "keycloak"
}

variable "name" {
  description = "Resource name prefix"
  type        = string
  default     = "keycloak"
}

variable "image" {
  description = "Keycloak container image"
  type        = string
  default     = "quay.io/keycloak/keycloak:26.1"
}

variable "replicas" {
  description = "Number of Keycloak replicas (1 for H2 mode)"
  type        = number
  default     = 1

  validation {
    condition     = var.replicas == 1
    error_message = "Only 1 replica is supported with H2 embedded database."
  }
}

variable "admin_user" {
  description = "Keycloak bootstrap admin username"
  type        = string
  default     = "admin"
}

variable "admin_password" {
  description = "Keycloak bootstrap admin password"
  type        = string
  sensitive   = true
}

variable "ingress_host" {
  description = "Hostname for the Keycloak ingress (e.g. sso.local.lan)"
  type        = string
}

variable "storage_size" {
  description = "Persistent volume size for H2 database"
  type        = string
  default     = "2Gi"
}

variable "storage_class" {
  description = "Storage class for the H2 data volume"
  type        = string
  default     = "local-path"
}

variable "cpu_request" {
  description = "CPU request"
  type        = string
  default     = "100m"
}

variable "memory_request" {
  description = "Memory request"
  type        = string
  default     = "256Mi"
}

variable "cpu_limit" {
  description = "CPU limit"
  type        = string
  default     = "500m"
}

variable "memory_limit" {
  description = "Memory limit"
  type        = string
  default     = "512Mi"
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}
