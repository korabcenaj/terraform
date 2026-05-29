variable "release_name" {
  description = "Helm release name for Rancher Turtles"
  type        = string
  default     = "rancher-turtles"
}

variable "chart_version" {
  description = "Rancher Turtles Helm chart version"
  type        = string
  default     = "109.0.1+up0.26.1"
}

variable "tags" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}
