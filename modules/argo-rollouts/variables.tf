variable "namespace" {
  description = "Namespace where Argo Rollouts will be installed"
  type        = string
  default     = "argo-rollouts"
}

variable "release_name" {
  description = "Helm release name for Argo Rollouts"
  type        = string
  default     = "argo-rollouts"
}

variable "chart_version" {
  description = "Argo Rollouts Helm chart version"
  type        = string
  default     = "2.39.5"
}

variable "dashboard_enabled" {
  description = "Enable Argo Rollouts dashboard service"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}
