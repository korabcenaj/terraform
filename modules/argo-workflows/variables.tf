variable "enable_argo_events" {
  description = "Whether Argo Events is deployed"
  type        = bool
  default     = true
}

variable "enable_argo_rollouts" {
  description = "Whether Argo Rollouts is deployed"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}
