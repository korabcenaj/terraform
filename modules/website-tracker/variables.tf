variable "release_name" {
  description = "Helm release name for Website Tracker"
  type        = string
  default     = "website-tracker"
}

variable "chart_path" {
  description = "Path or name of the website-tracker Helm chart"
  type        = string
  default     = "./charts/website-tracker"
}

variable "chart_version" {
  description = "Website Tracker chart version"
  type        = string
  default     = "0.1.0"
}

variable "image_registry" {
  description = "Container image registry"
  type        = string
  default     = "192.168.1.13:30002"
}

variable "image_repository" {
  description = "Container image repository"
  type        = string
  default     = "library/website-tracker-operator"
}

variable "image_tag" {
  description = "Container image tag"
  type        = string
  default     = "latest"
}

variable "image_pull_secret" {
  description = "Image pull secret name"
  type        = string
  default     = "harbor-pull-secret"
}

variable "tags" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}
