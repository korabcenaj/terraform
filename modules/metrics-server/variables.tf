variable "namespace" {
  description = "Namespace where metrics-server will be installed"
  type        = string
  default     = "kube-system"
}

variable "release_name" {
  description = "Metrics-server deployment name"
  type        = string
  default     = "metrics-server"
}

variable "image" {
  description = "Metrics-server container image"
  type        = string
  default     = "registry.k8s.io/metrics-server/metrics-server:v0.7.2"
}

variable "replicas" {
  description = "Number of metrics-server replicas"
  type        = number
  default     = 1
}

variable "cpu_request" {
  description = "CPU request for metrics-server"
  type        = string
  default     = "100m"
}

variable "memory_request" {
  description = "Memory request for metrics-server"
  type        = string
  default     = "200Mi"
}

variable "cpu_limit" {
  description = "CPU limit for metrics-server"
  type        = string
  default     = "200m"
}

variable "memory_limit" {
  description = "Memory limit for metrics-server"
  type        = string
  default     = "400Mi"
}
