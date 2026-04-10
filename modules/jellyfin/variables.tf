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
