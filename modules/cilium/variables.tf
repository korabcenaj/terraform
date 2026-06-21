variable "release_name" {
  description = "Helm release name for Cilium"
  type        = string
  default     = "cilium"
}

variable "chart_version" {
  description = "Cilium Helm chart version"
  type        = string
  default     = "1.19.4"
}

variable "namespace" {
  description = "Namespace for Cilium"
  type        = string
  default     = "kube-system"
}

variable "timeout" {
  description = "Helm install timeout in seconds"
  type        = number
  default     = 900
}

variable "cluster_name" {
  description = "Kubernetes cluster name used by Cilium"
  type        = string
}

variable "cluster_id" {
  description = "Numeric cluster ID for Cilium (must be unique per cluster in mesh)"
  type        = number
  default     = 1
}

variable "k8s_api_host" {
  description = "Kubernetes API server IP/host that Cilium should connect to"
  type        = string
}

variable "k8s_api_port" {
  description = "Kubernetes API server port"
  type        = string
  default     = "6443"
}

variable "ipv4_native_routing_cidr" {
  description = "CIDR for native IPv4 routing (Pod CIDR)"
  type        = string
  default     = "10.244.0.0/16"
}

variable "mtu" {
  description = "MTU for Cilium-managed interfaces"
  type        = string
  default     = "1400"
}

variable "cpu_request" {
  description = "CPU request for Cilium agent"
  type        = string
  default     = "100m"
}

variable "memory_request" {
  description = "Memory request for Cilium agent"
  type        = string
  default     = "512Mi"
}

variable "cpu_limit" {
  description = "CPU limit for Cilium agent"
  type        = string
  default     = "1000m"
}

variable "memory_limit" {
  description = "Memory limit for Cilium agent"
  type        = string
  default     = "1Gi"
}

variable "tags" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}
