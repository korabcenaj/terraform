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
  default     = "pihole/pihole:latest"
}

variable "timezone" {
  description = "Timezone for Pi-hole"
  type        = string
  default     = "UTC"
}

variable "web_password" {
  description = "Web UI password for Pi-hole"
  type        = string
  default     = "admin"
  sensitive   = true
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
