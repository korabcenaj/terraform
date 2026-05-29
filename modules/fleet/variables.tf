variable "release_name" {
  description = "Helm release name for Fleet"
  type        = string
  default     = "fleet"
}

variable "chart_version" {
  description = "Fleet Helm chart version"
  type        = string
  default     = "109.0.1+up0.15.1"
}

variable "fleet_crd_chart_version" {
  description = "Fleet CRD Helm chart version"
  type        = string
  default     = "109.0.1+up0.15.1"
}

variable "rancher_url" {
  description = "Rancher server URL for Fleet agent registration"
  type        = string
  default     = "https://rancher.local.lan"
}

variable "tags" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}
