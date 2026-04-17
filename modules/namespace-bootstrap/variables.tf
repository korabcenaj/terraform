variable "name" {
  description = "Namespace name to bootstrap"
  type        = string
}

variable "pod_security_enforce" {
  description = "PSS enforce label value"
  type        = string
  default     = "baseline"
}

variable "pod_security_audit" {
  description = "PSS audit label value"
  type        = string
  default     = "restricted"
}

variable "pod_security_warn" {
  description = "PSS warn label value"
  type        = string
  default     = "restricted"
}

variable "pod_limit" {
  description = "Maximum pod count quota"
  type        = string
  default     = "10"
}

variable "cpu_request_quota" {
  description = "Total CPU requests quota"
  type        = string
  default     = "500m"
}

variable "memory_request_quota" {
  description = "Total memory requests quota"
  type        = string
  default     = "512Mi"
}

variable "cpu_limit_quota" {
  description = "Total CPU limits quota"
  type        = string
  default     = "1000m"
}

variable "memory_limit_quota" {
  description = "Total memory limits quota"
  type        = string
  default     = "1Gi"
}

variable "default_cpu_request" {
  description = "Default container CPU request"
  type        = string
  default     = "100m"
}

variable "default_memory_request" {
  description = "Default container memory request"
  type        = string
  default     = "128Mi"
}

variable "default_cpu_limit" {
  description = "Default container CPU limit"
  type        = string
  default     = "250m"
}

variable "default_memory_limit" {
  description = "Default container memory limit"
  type        = string
  default     = "256Mi"
}

variable "create_default_deny" {
  description = "Whether to create a default-deny network policy"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}
