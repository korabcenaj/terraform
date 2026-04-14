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

variable "tags" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}