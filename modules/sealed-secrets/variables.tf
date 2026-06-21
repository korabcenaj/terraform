variable "image" {
  description = "Sealed Secrets controller image"
  type        = string
  default     = "docker.io/bitnami/sealed-secrets-controller:v0.24.1"
}

variable "tags" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}
