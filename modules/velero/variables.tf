variable "namespace" {
  description = "Namespace where Velero will be installed"
  type        = string
  default     = "velero"
}

variable "release_name" {
  description = "Helm release name for Velero"
  type        = string
  default     = "velero"
}

variable "chart_version" {
  description = "Velero Helm chart version"
  type        = string
  default     = "8.5.0"
}

variable "bucket_name" {
  description = "Object storage bucket used by Velero backups"
  type        = string
  default     = "velero"
}

variable "s3_url" {
  description = "S3-compatible URL used by Velero (e.g., MinIO endpoint)"
  type        = string
}

variable "access_key" {
  description = "S3 access key for Velero backup storage"
  type        = string
}

variable "secret_key" {
  description = "S3 secret key for Velero backup storage"
  type        = string
  sensitive   = true
}

variable "aws_plugin_image" {
  description = "Container image for the Velero AWS/S3-compatible plugin init container"
  type        = string
  default     = "velero/velero-plugin-for-aws:v1.10.1"
}

variable "tags" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "create_backup_schedule" {
  description = "Create a Velero Schedule resource for automated periodic backups"
  type        = bool
  default     = true
}

variable "schedule_name" {
  description = "Name of the Velero Schedule resource"
  type        = string
  default     = "daily-backup"
}

variable "schedule_cron" {
  description = "Cron expression for the Velero backup schedule (UTC)"
  type        = string
  default     = "0 2 * * *"
}

variable "backup_namespaces" {
  description = "List of namespaces to include in each scheduled backup. Use [\"*\"] for all namespaces."
  type        = list(string)
  default     = ["*"]
}

variable "backup_ttl" {
  description = "Retention period for scheduled backups (Go duration string, e.g. 720h0m0s = 30 days)"
  type        = string
  default     = "720h0m0s"
}