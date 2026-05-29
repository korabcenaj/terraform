variable "release_name" {
  description = "Helm release name for Falco"
  type        = string
  default     = "falco"
}

variable "chart_version" {
  description = "Falco Helm chart version"
  type        = string
  default     = "8.0.2"
}

variable "tags" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}
