variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
}

variable "replicas" {
  description = "Number of replicas"
  type        = number
  default     = 1
}

variable "cpu_request" {
  description = "CPU request"
  type        = string
  default     = "250m"
}

variable "memory_request" {
  description = "Memory request"
  type        = string
  default     = "256Mi"
}

variable "cpu_limit" {
  description = "CPU limit"
  type        = string
  default     = "500m"
}

variable "memory_limit" {
  description = "Memory limit"
  type        = string
  default     = "1Gi"
}

variable "ingress_host" {
  description = "Hostname used by the qBittorrent ingress"
  type        = string
}

variable "node_name" {
  description = "Node name where qBittorrent data lives (must match the local PV path)"
  type        = string
}

variable "data_path" {
  description = "Host path on node_name that stores qBittorrent config/data"
  type        = string
  default     = "/var/lib/qbittorrent-data"
}

variable "storage_size" {
  description = "Persistent volume size for qBittorrent config data"
  type        = string
  default     = "5Gi"
}

variable "tags" {
  description = "Tags for resources"
  type        = map(string)
  default     = {}
}
