variable "release_name" {
  description = "Helm release name for MetalLB"
  type        = string
  default     = "metallb"
}

variable "chart_version" {
  description = "MetalLB Helm chart version"
  type        = string
  default     = "0.15.3"
}

variable "tags" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}
