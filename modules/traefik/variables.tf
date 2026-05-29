variable "release_name" {
  description = "Helm release name for Traefik"
  type        = string
  default     = "traefik"
}

variable "chart_version" {
  description = "Traefik Helm chart version"
  type        = string
  default     = "40.2.0"
}

variable "replicas" {
  description = "Number of Traefik replicas"
  type        = number
  default     = 2
}

variable "service_type" {
  description = "Traefik service type (LoadBalancer, NodePort, ClusterIP)"
  type        = string
  default     = "LoadBalancer"
}

variable "load_balancer_ip" {
  description = "Static IP for Traefik LoadBalancer service"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}
