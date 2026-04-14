variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "kubeconfig_context" {
  description = "Kubernetes context to use"
  type        = string
  default     = "kubernetes-admin@kubernetes"
}

variable "cluster_name" {
  description = "Kubernetes cluster name"
  type        = string
  default     = "home-lab"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "ingress_base_domain" {
  description = "Base domain used for ingress hostnames, e.g. local.lan"
  type        = string
  default     = "local.lan"
}

# Enable/disable modules
variable "enable_portfolio" {
  description = "Enable portfolio application"
  type        = bool
  default     = true
}

variable "manage_portfolio_workload" {
  description = "Whether Terraform should manage the portfolio deployment/service/ingress, or leave that to another controller such as Argo CD"
  type        = bool
  default     = false
}

variable "enable_jellyfin" {
  description = "Enable Jellyfin media server"
  type        = bool
  default     = true
}

variable "enable_qbittorrent" {
  description = "Enable qBittorrent application"
  type        = bool
  default     = true
}

variable "enable_pihole" {
  description = "Enable Pi-hole DNS"
  type        = bool
  default     = true
}

variable "pihole_web_password" {
  description = "Pi-hole web UI password"
  type        = string
  sensitive   = true

  validation {
    condition = (
      length(trimspace(var.pihole_web_password)) >= 12 &&
      can(regex("[A-Z]", trimspace(var.pihole_web_password))) &&
      can(regex("[a-z]", trimspace(var.pihole_web_password))) &&
      can(regex("[0-9]", trimspace(var.pihole_web_password))) &&
      can(regex("[^A-Za-z0-9]", trimspace(var.pihole_web_password))) &&
      lower(trimspace(var.pihole_web_password)) != "admin" &&
      lower(trimspace(var.pihole_web_password)) != "password" &&
      lower(trimspace(var.pihole_web_password)) != "changeme"
    )
    error_message = "pihole_web_password must be at least 12 characters, include uppercase/lowercase letters, a number, and a symbol, and must not be a weak default such as admin, password, or changeme."
  }
}

variable "enable_monitoring" {
  description = "Enable monitoring stack (ingress + network policies for existing Prometheus/Grafana)"
  type        = bool
  default     = true
}

variable "enable_metrics_server" {
  description = "Enable metrics-server for kubectl top and autoscaling signals"
  type        = bool
  default     = true
}

variable "enable_network_policies" {
  description = "Enable network policies"
  type        = bool
  default     = true
}

variable "enable_pod_security_standards" {
  description = "Enable Pod Security Standards"
  type        = bool
  default     = true
}

variable "enable_resource_quotas" {
  description = "Enable Resource Quotas on application namespaces"
  type        = bool
  default     = true
}

variable "enable_pod_disruption_budgets" {
  description = "Enable Pod Disruption Budgets for HA"
  type        = bool
  default     = true
}

variable "enable_cert_manager" {
  description = "Deploy cert-manager via Helm (manages TLS certificates for all ingresses)"
  type        = bool
  default     = true
}

variable "cert_manager_chart_version" {
  description = "cert-manager Helm chart version"
  type        = string
  default     = "v1.17.1"
}

variable "enable_ingress_nginx" {
  description = "Deploy ingress-nginx via Helm (the cluster's ingress controller)"
  type        = bool
  default     = true
}

variable "ingress_nginx_chart_version" {
  description = "ingress-nginx Helm chart version"
  type        = string
  default     = "4.12.1"
}

variable "ingress_nginx_service_type" {
  description = "Service type for the ingress-nginx controller (LoadBalancer or NodePort)"
  type        = string
  default     = "LoadBalancer"
}

variable "ingress_nginx_replicas" {
  description = "Number of ingress-nginx controller replicas"
  type        = number
  default     = 1
}

variable "enable_kube_prometheus_stack" {
  description = "Deploy kube-prometheus-stack via Helm (Prometheus, Grafana, Alertmanager, node-exporter, kube-state-metrics)"
  type        = bool
  default     = true
}

variable "enable_loki" {
  description = "Deploy Loki + Promtail via Helm for centralized cluster log aggregation"
  type        = bool
  default     = false
}

variable "enable_minio" {
  description = "Deploy MinIO via Helm as in-cluster object storage"
  type        = bool
  default     = false
}

variable "enable_velero" {
  description = "Deploy Velero via Helm for cluster backup and restore"
  type        = bool
  default     = false
}

variable "enable_vault" {
  description = "Deploy HashiCorp Vault via Helm for secret management"
  type        = bool
  default     = false
}

variable "enable_external_secrets" {
  description = "Deploy External Secrets Operator via Helm"
  type        = bool
  default     = false
}

variable "enable_argocd" {
  description = "Deploy Argo CD via Helm"
  type        = bool
  default     = false
}

variable "enable_tempo" {
  description = "Deploy Grafana Tempo via Helm for distributed tracing"
  type        = bool
  default     = false
}

variable "kube_prometheus_stack_chart_version" {
  description = "kube-prometheus-stack Helm chart version"
  type        = string
  default     = "70.4.0"
}

variable "loki_chart_version" {
  description = "loki-stack Helm chart version"
  type        = string
  default     = "2.10.2"
}

variable "loki_storage_size" {
  description = "Loki persistent volume size"
  type        = string
  default     = "20Gi"
}

variable "loki_storage_class" {
  description = "Storage class for Loki persistent volume"
  type        = string
  default     = "local-path"
}

variable "minio_chart_version" {
  description = "MinIO Helm chart version"
  type        = string
  default     = "5.4.0"
}

variable "velero_chart_version" {
  description = "Velero Helm chart version"
  type        = string
  default     = "8.5.0"
}

variable "vault_chart_version" {
  description = "Vault Helm chart version"
  type        = string
  default     = "0.28.1"
}

variable "external_secrets_chart_version" {
  description = "External Secrets Helm chart version"
  type        = string
  default     = "0.14.1"
}

variable "argocd_chart_version" {
  description = "Argo CD Helm chart version"
  type        = string
  default     = "7.8.5"
}

variable "tempo_chart_version" {
  description = "Tempo Helm chart version"
  type        = string
  default     = "1.17.2"
}

variable "minio_storage_size" {
  description = "MinIO persistent volume size"
  type        = string
  default     = "50Gi"
}

variable "minio_storage_class" {
  description = "Storage class for MinIO persistent volume"
  type        = string
  default     = "local-path"
}

variable "velero_bucket_name" {
  description = "Bucket name used by Velero for backups"
  type        = string
  default     = "velero"
}

variable "velero_s3_url" {
  description = "S3-compatible URL used by Velero (e.g. MinIO service URL)"
  type        = string
  default     = "http://minio.minio.svc.cluster.local:9000"
}

variable "vault_storage_size" {
  description = "Vault persistent volume size"
  type        = string
  default     = "10Gi"
}

variable "vault_storage_class" {
  description = "Storage class for Vault persistent volume"
  type        = string
  default     = "local-path"
}

variable "tempo_storage_size" {
  description = "Tempo persistent volume size"
  type        = string
  default     = "20Gi"
}

variable "tempo_storage_class" {
  description = "Storage class for Tempo persistent volume"
  type        = string
  default     = "local-path"
}

variable "create_vault_cluster_secret_store" {
  description = "Create a Vault-backed ClusterSecretStore in External Secrets"
  type        = bool
  default     = false
}

variable "external_secrets_cluster_secret_store_name" {
  description = "ClusterSecretStore name used for Vault integration"
  type        = string
  default     = "vault-backend"
}

variable "external_secrets_vault_server" {
  description = "Vault URL used by External Secrets"
  type        = string
  default     = "http://vault.vault.svc.cluster.local:8200"
}

variable "external_secrets_vault_kv_path" {
  description = "Vault KV mount path used by External Secrets"
  type        = string
  default     = "kv"
}

variable "minio_root_user" {
  description = "MinIO root username"
  type        = string
  default     = "minioadmin"
}

variable "minio_root_password" {
  description = "MinIO root password"
  type        = string
  sensitive   = true
  default     = "CHANGE_ME_MINIO_PASSWORD"
}

variable "vault_token" {
  description = "Vault token used for External Secrets bootstrap"
  type        = string
  sensitive   = true
  default     = "CHANGE_ME_VAULT_TOKEN"
}

variable "argocd_admin_password_bcrypt" {
  description = "Optional bcrypt hash for Argo CD admin password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
}

variable "prometheus_retention" {
  description = "Prometheus data retention period"
  type        = string
  default     = "30d"
}

variable "prometheus_storage_size" {
  description = "Prometheus persistent volume size"
  type        = string
  default     = "20Gi"
}

variable "prometheus_storage_class" {
  description = "Storage class for Prometheus persistent volume"
  type        = string
  default     = "local-path"
}

variable "grafana_storage_size" {
  description = "Grafana persistent volume size"
  type        = string
  default     = "2Gi"
}

variable "grafana_storage_class" {
  description = "Storage class for Grafana persistent volume"
  type        = string
  default     = "local-path"
}

# Application configurations
variable "portfolio_replicas" {
  description = "Number of portfolio replicas"
  type        = number
  default     = 1
}

variable "jellyfin_replicas" {
  description = "Number of jellyfin replicas"
  type        = number
  default     = 1
}

variable "qbittorrent_replicas" {
  description = "Number of qbittorrent replicas"
  type        = number
  default     = 1
}

# Storage
variable "jellyfin_storage_class" {
  description = "Storage class for Jellyfin data"
  type        = string
  default     = "local-path"
}

variable "jellyfin_config_size" {
  description = "Jellyfin config volume size"
  type        = string
  default     = "20Gi"
}

variable "jellyfin_cache_size" {
  description = "Jellyfin cache volume size"
  type        = string
  default     = "5Gi"
}

variable "jellyfin_node_name" {
  description = "Node name to pin Jellyfin on (must have access to media files)"
  type        = string
}

variable "jellyfin_media_path" {
  description = "Host path for Jellyfin media files"
  type        = string
}

# Resource limits
variable "default_cpu_request" {
  description = "Default CPU request for pods"
  type        = string
  default     = "100m"
}

variable "default_memory_request" {
  description = "Default memory request for pods"
  type        = string
  default     = "128Mi"
}

variable "default_cpu_limit" {
  description = "Default CPU limit for pods"
  type        = string
  default     = "250m"
}

variable "default_memory_limit" {
  description = "Default memory limit for pods"
  type        = string
  default     = "256Mi"
}

# ---------------------------------------------------------------------------
# OAuth2 Proxy
# ---------------------------------------------------------------------------

variable "enable_oauth2_proxy" {
  description = "Deploy OAuth2 Proxy for SSO/forward authentication in front of all ingresses"
  type        = bool
  default     = false
}

variable "oauth2_proxy_chart_version" {
  description = "OAuth2 Proxy Helm chart version"
  type        = string
  default     = "7.7.1"
}

variable "oauth2_proxy_provider" {
  description = "OAuth2 provider type (e.g. github, oidc, google)"
  type        = string
  default     = "github"
}

variable "oauth2_proxy_email_domain" {
  description = "Allowed email domain for OAuth2 authentication. Use '*' to allow any."
  type        = string
  default     = "*"
}

variable "oauth2_proxy_client_id" {
  description = "OAuth2 application client ID"
  type        = string
  sensitive   = true
  default     = "CHANGE_ME_CLIENT_ID"
}

variable "oauth2_proxy_client_secret" {
  description = "OAuth2 application client secret"
  type        = string
  sensitive   = true
  default     = "CHANGE_ME_CLIENT_SECRET"
}

variable "oauth2_proxy_cookie_secret" {
  description = "Cookie encryption secret (16/24/32 bytes base64). Generate: openssl rand -base64 32 | tr -- '+/' '-_' | tr -d '='"
  type        = string
  sensitive   = true
  default     = "CHANGE_ME_COOKIE_SECRET"
}

# ---------------------------------------------------------------------------
# Kyverno
# ---------------------------------------------------------------------------

variable "enable_kyverno" {
  description = "Deploy Kyverno policy engine for admission-controller-based policy enforcement"
  type        = bool
  default     = false
}

variable "kyverno_chart_version" {
  description = "Kyverno Helm chart version"
  type        = string
  default     = "3.2.6"
}

variable "kyverno_enforcement_mode" {
  description = "Kyverno policy action: 'Audit' logs violations, 'Enforce' blocks non-compliant resources"
  type        = string
  default     = "Audit"
}

variable "kyverno_create_policies" {
  description = "Create Kyverno ClusterPolicy resources. Enable only after Kyverno CRDs are registered in the cluster (i.e. after the Helm chart has been applied)."
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------------
# Local identity provider and native app OIDC
# ---------------------------------------------------------------------------

variable "enable_keycloak" {
  description = "Deploy a local Keycloak identity provider for LAN-only authentication"
  type        = bool
  default     = false
}

variable "keycloak_chart_version" {
  description = "Keycloak Helm chart version"
  type        = string
  default     = "25.2.0"
}

variable "keycloak_admin_user" {
  description = "Keycloak admin username"
  type        = string
  default     = "admin"
}

variable "keycloak_admin_password" {
  description = "Keycloak admin password"
  type        = string
  sensitive   = true
  default     = "CHANGE_ME_KEYCLOAK_ADMIN_PASSWORD"
}

variable "keycloak_realm" {
  description = "Realm name intended for homelab OIDC clients"
  type        = string
  default     = "homelab"
}

variable "keycloak_postgresql_username" {
  description = "PostgreSQL username for the bundled Keycloak database"
  type        = string
  default     = "keycloak"
}

variable "keycloak_postgresql_password" {
  description = "PostgreSQL password for the bundled Keycloak database"
  type        = string
  sensitive   = true
  default     = "CHANGE_ME_KEYCLOAK_DB_PASSWORD"
}

variable "keycloak_postgresql_database" {
  description = "PostgreSQL database name for Keycloak"
  type        = string
  default     = "keycloak"
}

variable "keycloak_postgresql_storage_class" {
  description = "Storage class for the bundled Keycloak PostgreSQL volume"
  type        = string
  default     = "local-path"
}

variable "keycloak_postgresql_storage_size" {
  description = "Persistent volume size for the bundled Keycloak PostgreSQL database"
  type        = string
  default     = "8Gi"
}

variable "keycloak_bootstrap_enabled" {
  description = "Bootstrap the homelab realm and known OIDC clients declaratively inside Keycloak"
  type        = bool
  default     = true
}

variable "enable_argocd_oidc" {
  description = "Enable native OIDC login in Argo CD using the local identity provider"
  type        = bool
  default     = false
}

variable "argocd_oidc_client_id" {
  description = "OIDC client ID for Argo CD"
  type        = string
  sensitive   = true
  default     = "argocd"
}

variable "argocd_oidc_client_secret" {
  description = "OIDC client secret for Argo CD"
  type        = string
  sensitive   = true
  default     = "CHANGE_ME_ARGOCD_OIDC_SECRET"
}

variable "enable_grafana_oidc" {
  description = "Enable native OIDC login in Grafana using the local identity provider"
  type        = bool
  default     = false
}

variable "grafana_oidc_client_id" {
  description = "OIDC client ID for Grafana"
  type        = string
  sensitive   = true
  default     = "grafana"
}

variable "grafana_oidc_client_secret" {
  description = "OIDC client secret for Grafana"
  type        = string
  sensitive   = true
  default     = "CHANGE_ME_GRAFANA_OIDC_SECRET"
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    managed-by  = "terraform"
    environment = "production"
    cluster     = "home-lab"
  }
}
