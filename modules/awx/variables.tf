# ---------------------------------------------------------------------------
# AWX (Ansible Automation Platform upstream) — Kubernetes deployment
# ---------------------------------------------------------------------------

variable "namespace" {
  description = "Kubernetes namespace for AWX"
  type        = string
  default     = "awx"
}

variable "release_name" {
  description = "Helm release name for the AWX Operator"
  type        = string
  default     = "awx-operator"
}

variable "operator_chart_version" {
  description = "AWX Operator Helm chart version"
  type        = string
  default     = "2.19.1"
}

variable "awx_instance_name" {
  description = "Name of the AWX custom resource"
  type        = string
  default     = "awx"
}

variable "awx_image_version" {
  description = "AWX container image version tag"
  type        = string
  default     = "24.6.1"
}

variable "admin_user" {
  description = "AWX admin username"
  type        = string
  default     = "admin"
}

variable "admin_password" {
  description = "AWX admin password (leave empty to auto-generate)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "admin_email" {
  description = "AWX admin email"
  type        = string
  default     = "admin@local.lan"
}

variable "ingress_host" {
  description = "Ingress hostname for AWX web UI"
  type        = string
}

variable "ingress_class_name" {
  description = "Ingress class name for AWX"
  type        = string
  default     = "traefik"
}

variable "cluster_issuer" {
  description = "cert-manager ClusterIssuer for AWX TLS"
  type        = string
  default     = "local-lan-ca"
}

variable "postgres_storage_class" {
  description = "Storage class for AWX PostgreSQL"
  type        = string
  default     = "local-path"
}

variable "postgres_storage_size" {
  description = "Persistent volume size for AWX PostgreSQL"
  type        = string
  default     = "10Gi"
}

variable "web_replicas" {
  description = "Number of AWX web replicas"
  type        = number
  default     = 1
}

variable "task_replicas" {
  description = "Number of AWX task replicas"
  type        = number
  default     = 1
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
}
