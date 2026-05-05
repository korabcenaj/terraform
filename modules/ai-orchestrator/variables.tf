variable "namespace" {
  description = "Namespace for AI orchestrator workloads"
  type        = string
  default     = "ai-orchestrator"
}

variable "api_gateway_port" {
  description = "Port exposed by the api-gateway service"
  type        = number
  default     = 8080
}

variable "cpu_request" {
  description = "Default CPU request for AI workload resource quota"
  type        = string
  default     = "500m"
}

variable "memory_request" {
  description = "Default memory request for AI workload resource quota"
  type        = string
  default     = "1Gi"
}

variable "cpu_limit" {
  description = "Total CPU limit for the namespace resource quota"
  type        = string
  default     = "16"
}

variable "memory_limit" {
  description = "Total memory limit for the namespace resource quota"
  type        = string
  default     = "32Gi"
}

variable "gpu_limit" {
  description = "Maximum nvidia.com/gpu devices allocatable across the namespace"
  type        = number
  default     = 2
}

variable "max_pods" {
  description = "Maximum pod count in the ai-orchestrator namespace"
  type        = number
  default     = 20
}

variable "max_pvcs" {
  description = "Maximum PersistentVolumeClaims in the ai-orchestrator namespace"
  type        = number
  default     = 10
}

variable "tags" {
  description = "Labels applied to all resources"
  type        = map(string)
  default     = {}
}
