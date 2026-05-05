variable "namespace" {
  description = "Kubernetes namespace for qBittorrent"
  type        = string
  default     = "qbittorrent"
}

variable "replicas" {
  description = "Number of qBittorrent replicas (should be 1 to avoid torrent file conflicts)"
  type        = number
  default     = 1
}

variable "image" {
  description = "qBittorrent container image"
  type        = string
  default     = "linuxserver/qbittorrent:5.1.4"
}

variable "storage_class" {
  description = "Storage class for config and downloads volumes"
  type        = string
  default     = "local-path"
}

variable "config_size" {
  description = "Config volume size"
  type        = string
  default     = "2Gi"
}

variable "downloads_size" {
  description = "Downloads volume size"
  type        = string
  default     = "200Gi"
}

variable "node_name" {
  description = "Node name to pin qBittorrent scheduling"
  type        = string
  default     = ""
}

variable "web_ui_port" {
  description = "qBittorrent Web UI port"
  type        = number
  default     = 8080
}

variable "torrent_port" {
  description = "Torrent traffic port (TCP+UDP)"
  type        = number
  default     = 6881
}

variable "puid" {
  description = "UID for the linuxserver container process"
  type        = number
  default     = 1000
}

variable "pgid" {
  description = "GID for the linuxserver container process"
  type        = number
  default     = 1000
}

variable "timezone" {
  description = "Timezone for the container"
  type        = string
  default     = "UTC"
}

variable "cpu_request" {
  description = "CPU request"
  type        = string
  default     = "100m"
}

variable "memory_request" {
  description = "Memory request"
  type        = string
  default     = "128Mi"
}

variable "cpu_limit" {
  description = "CPU limit"
  type        = string
  default     = "500m"
}

variable "memory_limit" {
  description = "Memory limit"
  type        = string
  default     = "512Mi"
}

variable "ingress_host" {
  description = "Hostname for the qBittorrent Web UI ingress"
  type        = string
}

variable "tags" {
  description = "Labels applied to all resources"
  type        = map(string)
  default     = {}
}
