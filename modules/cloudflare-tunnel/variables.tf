variable "namespace" {
  description = "Namespace for cloudflared connector"
  type        = string
  default     = "cloudflare-tunnel"
}

variable "name" {
  description = "Name prefix for cloudflared resources"
  type        = string
  default     = "cloudflared"
}

variable "image" {
  description = "cloudflared container image"
  type        = string
  default     = "cloudflare/cloudflared:latest"
}

variable "tunnel_token_secret_name" {
  description = "Name of the pre-existing Kubernetes secret containing key 'token' with the Cloudflare Tunnel token. Create it out-of-band with: kubectl create secret generic <name> --from-literal=token=<TOKEN> -n <namespace>"
  type        = string
  default     = "cloudflared-token"
}

variable "replicas" {
  description = "Number of cloudflared connector replicas"
  type        = number
  default     = 1
}

variable "cpu_request" {
  description = "CPU request for cloudflared"
  type        = string
  default     = "50m"
}

variable "memory_request" {
  description = "Memory request for cloudflared"
  type        = string
  default     = "64Mi"
}

variable "cpu_limit" {
  description = "CPU limit for cloudflared"
  type        = string
  default     = "500m"
}

variable "memory_limit" {
  description = "Memory limit for cloudflared"
  type        = string
  default     = "256Mi"
}

variable "tags" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}
