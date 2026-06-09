variable "namespace" {
  description = "Namespace to apply the LimitRange to"
  type        = string
}

variable "default_cpu_request" {
  description = "Default CPU request when container has none"
  type        = string
  default     = "50m"
}

variable "default_memory_request" {
  description = "Default memory request when container has none"
  type        = string
  default     = "64Mi"
}

variable "default_cpu_limit" {
  description = "Default CPU limit when container has none"
  type        = string
  default     = "500m"
}

variable "default_memory_limit" {
  description = "Default memory limit when container has none"
  type        = string
  default     = "512Mi"
}

variable "max_cpu_limit" {
  description = "Maximum CPU any single container may request"
  type        = string
  default     = "2"
}

variable "max_memory_limit" {
  description = "Maximum memory any single container may request"
  type        = string
  default     = "4Gi"
}

variable "tags" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}
