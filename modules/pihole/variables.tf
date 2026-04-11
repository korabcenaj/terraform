variable "pihole_storage_size" {
  description = "Persistent storage size for Pi-hole data"
  type        = string
  default     = "1Gi"
}
variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
  default     = "pihole"
}

variable "replicas" {
  description = "Number of Pi-hole replicas"
  type        = number
  default     = 1
}

variable "image" {
  description = "Pi-hole Docker image"
  type        = string
  default     = "pihole/pihole:2024.07.0"
}

variable "timezone" {
  description = "Timezone for Pi-hole"
  type        = string
  default     = "UTC"
}

variable "web_password" {
  description = "Web UI password for Pi-hole"
  type        = string
  sensitive   = true

  validation {
    condition = (
      length(trimspace(var.web_password)) >= 12 &&
      can(regex("[A-Z]", trimspace(var.web_password))) &&
      can(regex("[a-z]", trimspace(var.web_password))) &&
      can(regex("[0-9]", trimspace(var.web_password))) &&
      can(regex("[^A-Za-z0-9]", trimspace(var.web_password))) &&
      lower(trimspace(var.web_password)) != "admin" &&
      lower(trimspace(var.web_password)) != "password" &&
      lower(trimspace(var.web_password)) != "changeme"
    )
    error_message = "web_password must be at least 12 characters, include uppercase/lowercase letters, a number, and a symbol, and must not be a weak default such as admin, password, or changeme."
  }
}

variable "cpu_request" {
  description = "CPU request"
  type        = string
  default     = "100m"
}

variable "memory_request" {
  description = "Memory request"
  type        = string
  default     = "128Mi"
}

variable "cpu_limit" {
  description = "CPU limit"
  type        = string
  default     = "250m"
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

variable "ingress_ip" {
  description = "IP address of the ingress controller (for local DNS wildcard)"
  type        = string
  default     = "192.168.1.200"
}

variable "local_dns_records" {
  description = "Additional local DNS records (map of hostname to IP)"
  type        = map(string)
  default     = {}
}
