variable "interactive_priority_name" {
  description = "PriorityClass name for interactive GPU workloads"
  type        = string
  default     = "gpu-interactive-high"
}

variable "interactive_priority_value" {
  description = "PriorityClass value for interactive GPU workloads"
  type        = number
  default     = 100000
}

variable "batch_priority_name" {
  description = "PriorityClass name for batch GPU workloads"
  type        = string
  default     = "gpu-batch-low"
}

variable "batch_priority_value" {
  description = "PriorityClass value for batch GPU workloads"
  type        = number
  default     = 10000
}

variable "tags" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}
