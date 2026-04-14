variable "namespace" {
  description = "Namespace where External Secrets Operator will be installed"
  type        = string
  default     = "external-secrets"
}

variable "release_name" {
  description = "Helm release name for External Secrets Operator"
  type        = string
  default     = "external-secrets"
}

variable "chart_version" {
  description = "external-secrets Helm chart version"
  type        = string
  default     = "0.14.1"
}

variable "create_vault_cluster_secret_store" {
  description = "Create a Vault-backed ClusterSecretStore"
  type        = bool
  default     = false
}

variable "cluster_secret_store_name" {
  description = "Name for the generated ClusterSecretStore resource"
  type        = string
  default     = "vault-backend"
}

variable "vault_server" {
  description = "Vault server URL used by External Secrets"
  type        = string
  default     = "http://vault.vault.svc.cluster.local:8200"
}

variable "vault_kv_path" {
  description = "Vault KV mount path used for secret retrieval"
  type        = string
  default     = "kv"
}

variable "vault_token" {
  description = "Vault token used for ClusterSecretStore bootstrap"
  type        = string
  sensitive   = true
  default     = "CHANGE_ME_VAULT_TOKEN"
}

variable "tags" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}