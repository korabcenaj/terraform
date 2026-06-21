variable "release_name" {
  description = "Helm release name for Rancher"
  type        = string
  default     = "rancher"
}

variable "chart_version" {
  description = "Rancher Helm chart version"
  type        = string
  default     = "2.14.1"
}

variable "hostname" {
  description = "Rancher server hostname"
  type        = string
  default     = "rancher.local.lan"
}

variable "replicas" {
  description = "Number of Rancher replicas"
  type        = number
  default     = 1
}

variable "ingress_tls_source" {
  description = "TLS source for Rancher ingress (secret, letsEncrypt, rancher)"
  type        = string
  default     = "secret"
}

variable "bootstrap_password" {
  description = "Rancher initial admin password (leave empty to auto-generate)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "tags" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}
