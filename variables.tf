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

variable "private_dns_ip" {
  description = "Optional override for private DNS upstream (IPv4). Leave empty to use service discovery via pihole.pihole.svc.cluster.local."
  type        = string
  default     = ""

  validation {
    condition = (
      trimspace(var.private_dns_ip) == "" ||
      can(regex("^(25[0-5]|2[0-4][0-9]|1?[0-9]{1,2})(\\.(25[0-5]|2[0-4][0-9]|1?[0-9]{1,2})){3}$", trimspace(var.private_dns_ip)))
    )
    error_message = "private_dns_ip must be empty or a valid IPv4 address."
  }
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

variable "enable_pihole" {
  description = "Enable Pi-hole DNS"
  type        = bool
  default     = true
}

variable "pihole_load_balancer_ip" {
  description = "Pi-hole LoadBalancer IP used by clients/routers for DNS"
  type        = string
  default     = "192.168.1.210"

  validation {
    condition     = can(regex("^(25[0-5]|2[0-4][0-9]|1?[0-9]{1,2})(\\.(25[0-5]|2[0-4][0-9]|1?[0-9]{1,2})){3}$", trimspace(var.pihole_load_balancer_ip)))
    error_message = "pihole_load_balancer_ip must be a valid IPv4 address."
  }
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

variable "enable_gpu_device_plugins" {
  description = "Enable GPU device plugin daemonsets (Intel, AMD, NVIDIA) in kube-system"
  type        = bool
  default     = true
}

variable "enable_intel_gpu_plugin" {
  description = "Enable Intel GPU device plugin daemonset"
  type        = bool
  default     = true
}

variable "enable_amd_gpu_plugin" {
  description = "Enable AMD GPU device plugin daemonset"
  type        = bool
  default     = true
}

variable "enable_nvidia_gpu_plugin" {
  description = "Enable NVIDIA GPU device plugin daemonset"
  type        = bool
  default     = true
}

variable "intel_gpu_plugin_image" {
  description = "Container image for Intel GPU plugin daemonset"
  type        = string
  default     = "intel/intel-gpu-plugin:devel"
}

variable "amd_gpu_plugin_image" {
  description = "Container image for AMD GPU plugin daemonset"
  type        = string
  default     = "rocm/k8s-device-plugin"
}

variable "nvidia_gpu_plugin_image" {
  description = "Container image for NVIDIA GPU plugin daemonset"
  type        = string
  default     = "nvcr.io/nvidia/k8s-device-plugin:v0.14.5"
}

variable "nvidia_node_selector" {
  description = "Node selector map for NVIDIA GPU device plugin scheduling"
  type        = map(string)
  default = {
    "kubernetes.io/hostname" = "k8s3"
  }
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
  default     = "v1.14.5"
}

variable "manage_cert_manager_controller" {
  description = "Whether Terraform should manage the cert-manager controller installation via Helm, or only the namespace and issuer bootstrap objects"
  type        = bool
  default     = true
}

variable "enable_ingress_nginx" {
  description = "Deploy ingress-nginx via Helm (the cluster's ingress controller)"
  type        = bool
  default     = true
}

variable "ingress_nginx_chart_version" {
  description = "ingress-nginx Helm chart version"
  type        = string
  default     = "4.15.1"
}

variable "ingress_nginx_service_type" {
  description = "Service type for the ingress-nginx controller (LoadBalancer or NodePort)"
  type        = string
  default     = "LoadBalancer"
}

variable "ingress_nginx_replicas" {
  description = "Number of ingress-nginx controller replicas"
  type        = number
  default     = 2
}

variable "ingress_nginx_limit_rps" {
  description = "Global ingress-nginx request rate limit per client IP (0 disables)"
  type        = number
  default     = 0

  validation {
    condition     = var.ingress_nginx_limit_rps >= 0
    error_message = "ingress_nginx_limit_rps must be >= 0."
  }
}

variable "ingress_nginx_limit_connections" {
  description = "Global ingress-nginx concurrent connection limit per client IP (0 disables)"
  type        = number
  default     = 0

  validation {
    condition     = var.ingress_nginx_limit_connections >= 0
    error_message = "ingress_nginx_limit_connections must be >= 0."
  }
}

variable "ingress_nginx_enable_modsecurity" {
  description = "Enable ModSecurity in ingress-nginx"
  type        = bool
  default     = false
}

variable "ingress_nginx_enable_owasp_crs" {
  description = "Enable OWASP CRS rules when ModSecurity is enabled"
  type        = bool
  default     = false
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
  default     = "82.18.0"
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
  default     = "9.4.17"
}

variable "argocd_create_app_project" {
  description = "Create a platform AppProject in Argo CD"
  type        = bool
  default     = false
}

variable "argocd_project_name" {
  description = "Name of the Argo CD AppProject"
  type        = string
  default     = "platform"
}

variable "argocd_create_bootstrap_app" {
  description = "Create a bootstrap Application in Argo CD pointing at a Git repository"
  type        = bool
  default     = false
}

variable "argocd_bootstrap_app_name" {
  description = "Name of the bootstrap Argo CD Application"
  type        = string
  default     = "platform-bootstrap"
}

variable "argocd_bootstrap_repo_url" {
  description = "Git repository URL for the Argo CD bootstrap Application (e.g. https://github.com/org/repo)"
  type        = string
  default     = ""
}

variable "argocd_bootstrap_repo_revision" {
  description = "Git ref (branch/tag/commit) for the bootstrap Application"
  type        = string
  default     = "HEAD"
}

variable "argocd_bootstrap_repo_path" {
  description = "Path within the repository containing Application manifests"
  type        = string
  default     = "."
}

variable "argocd_bootstrap_auto_sync" {
  description = "Enable automated sync (prune + self-heal) on the bootstrap Application"
  type        = bool
  default     = false
}

variable "tempo_chart_version" {
  description = "Tempo Helm chart version"
  type        = string
  default     = "1.24.4"
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

variable "external_secrets_vault_auth_method" {
  description = "Vault auth method for External Secrets ClusterSecretStore: \"token\" (static) or \"kubernetes\" (ServiceAccount-based)"
  type        = string
  default     = "token"
}

variable "external_secrets_vault_kubernetes_mount_path" {
  description = "Vault kubernetes auth mount path (used when external_secrets_vault_auth_method = \"kubernetes\")"
  type        = string
  default     = "kubernetes"
}

variable "external_secrets_vault_kubernetes_role" {
  description = "Vault kubernetes auth role bound to the ESO ServiceAccount"
  type        = string
  default     = "external-secrets"
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

variable "oauth2_proxy_insecure_skip_oidc_tls_verify" {
  description = "Allow oauth2-proxy to skip OIDC issuer and TLS certificate verification for internal self-signed IdPs"
  type        = bool
  default     = true
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

variable "alertmanager_enabled" {
  description = "Enable Alertmanager notification configuration. Requires alertmanager_webhook_url to be set."
  type        = bool
  default     = false
}

variable "alertmanager_webhook_url" {
  description = "Webhook URL for Alertmanager to send notifications to (Slack incoming webhook, n8n webhook, etc.)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "alertmanager_repeat_interval" {
  description = "How long to wait before re-sending an already-firing alert"
  type        = string
  default     = "4h"
}

variable "create_alert_rules" {
  description = "Create PrometheusRule with critical baseline alerts (node down, disk, OOM, crash-loop, Velero backup)"
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------
# n8n
# ---------------------------------------------------------------------------

variable "enable_n8n" {
  description = "Deploy n8n workflow automation platform via Helm"
  type        = bool
  default     = false
}

variable "n8n_chart_version" {
  description = "n8n Helm chart version (8gears community chart)"
  type        = string
  default     = "0.25.2"
}

variable "n8n_encryption_key" {
  description = "Encryption key for n8n stored credentials. Must be at least 24 characters and stable — changing it invalidates all saved credentials."
  type        = string
  sensitive   = true
  default     = "CHANGE_ME_N8N_ENCRYPTION_KEY_MIN24"
}

variable "n8n_storage_size" {
  description = "Persistent volume size for n8n data"
  type        = string
  default     = "5Gi"
}

variable "n8n_storage_class" {
  description = "Storage class for n8n persistent volume"
  type        = string
  default     = "local-path"
}

variable "n8n_timezone" {
  description = "Timezone for n8n scheduled workflows (e.g. Europe/Berlin)"
  type        = string
  default     = "UTC"
}

variable "n8n_webhook_url" {
  description = "Optional explicit base URL for n8n webhooks. Defaults to https://n8n.<ingress_base_domain>."
  type        = string
  default     = ""
}

# ---------------------------------------------------------------------------
# Cloudflare Tunnel (CGNAT-friendly inbound access)
# ---------------------------------------------------------------------------

variable "enable_cloudflare_tunnel" {
  description = "Deploy cloudflared in-cluster for outbound tunnel connectivity to Cloudflare"
  type        = bool
  default     = false
}

variable "cloudflare_tunnel_secret_name" {
  description = "Name of the pre-existing Kubernetes secret (in the cloudflare-tunnel namespace) holding key 'token'. Create it out-of-band: kubectl create secret generic <name> --from-literal=token=<TOKEN> -n cloudflare-tunnel"
  type        = string
  default     = "cloudflared-token"
}

variable "cloudflare_tunnel_image" {
  description = "cloudflared connector image"
  type        = string
  default     = "cloudflare/cloudflared:latest"
}

# ---------------------------------------------------------------------------
# Matrix Synapse (Android-friendly chat via Element)
# ---------------------------------------------------------------------------

variable "enable_matrix_synapse" {
  description = "Deploy Matrix Synapse chat server (recommended Android client: Element)"
  type        = bool
  default     = false
}

variable "matrix_synapse_image" {
  description = "Container image for Matrix Synapse"
  type        = string
  default     = "matrixdotorg/synapse:v1.131.0"
}

variable "matrix_synapse_server_name" {
  description = "Optional explicit Matrix server_name used for user IDs and federation. Leave empty to use chat.<ingress_base_domain>."
  type        = string
  default     = ""
}

variable "matrix_synapse_public_base_url" {
  description = "Optional explicit public base URL for Synapse. Leave empty to use https://chat.<ingress_base_domain>."
  type        = string
  default     = ""
}

variable "matrix_synapse_ingress_host" {
  description = "Optional explicit ingress host for Matrix Synapse. Leave empty to use chat.<ingress_base_domain>."
  type        = string
  default     = ""
}

variable "matrix_synapse_cluster_issuer" {
  description = "cert-manager ClusterIssuer used by Matrix Synapse ingress TLS"
  type        = string
  default     = "local-lan-ca"
}

variable "matrix_synapse_report_stats" {
  description = "Allow Synapse to report anonymous usage statistics"
  type        = bool
  default     = false
}

variable "matrix_synapse_storage_size" {
  description = "Persistent volume size for Matrix Synapse data"
  type        = string
  default     = "20Gi"
}

variable "matrix_synapse_storage_class" {
  description = "Storage class for Matrix Synapse persistent volume"
  type        = string
  default     = "local-path"
}

variable "matrix_synapse_cpu_request" {
  description = "CPU request for Matrix Synapse"
  type        = string
  default     = "250m"
}

variable "matrix_synapse_memory_request" {
  description = "Memory request for Matrix Synapse"
  type        = string
  default     = "512Mi"
}

variable "matrix_synapse_cpu_limit" {
  description = "CPU limit for Matrix Synapse"
  type        = string
  default     = "1000m"
}

variable "matrix_synapse_memory_limit" {
  description = "Memory limit for Matrix Synapse"
  type        = string
  default     = "2Gi"
}

variable "matrix_synapse_registration_shared_secret" {
  description = "Shared secret used for secure first-admin bootstrap and controlled user provisioning"
  type        = string
  sensitive   = true
  default     = "CHANGE_ME_MATRIX_SHARED_SECRET"
}

variable "matrix_synapse_bootstrap_admin_enabled" {
  description = "Run one-shot Kubernetes Job to create the first Matrix admin user"
  type        = bool
  default     = false
}

variable "matrix_synapse_bootstrap_admin_username" {
  description = "Username for first Matrix admin account"
  type        = string
  default     = "admin"
}

variable "matrix_synapse_bootstrap_admin_password" {
  description = "Password for first Matrix admin account"
  type        = string
  sensitive   = true
  default     = ""
}

variable "matrix_synapse_oidc_enabled" {
  description = "Enable OIDC login for Matrix Synapse"
  type        = bool
  default     = false
}

variable "matrix_synapse_oidc_issuer_url" {
  description = "Optional explicit OIDC issuer URL. Leave empty to use Keycloak realm URL derived from ingress_base_domain and keycloak_realm."
  type        = string
  default     = ""
}

variable "matrix_synapse_oidc_client_id" {
  description = "OIDC client ID for Matrix Synapse"
  type        = string
  sensitive   = true
  default     = "matrix-synapse"
}

variable "matrix_synapse_oidc_client_secret" {
  description = "OIDC client secret for Matrix Synapse"
  type        = string
  sensitive   = true
  default     = ""
}

variable "matrix_synapse_oidc_scopes" {
  description = "OIDC scopes requested by Matrix Synapse"
  type        = list(string)
  default     = ["openid", "profile", "email"]
}

variable "matrix_synapse_federation_enabled" {
  description = "Enable Matrix federation with external homeservers"
  type        = bool
  default     = false
}

variable "matrix_synapse_federation_domain_whitelist" {
  description = "Optional allow-list of external homeserver domains for federation. Empty means unrestricted when federation is enabled."
  type        = list(string)
  default     = []
}

variable "matrix_synapse_well_known_enabled" {
  description = "Expose .well-known/matrix/server and .well-known/matrix/client endpoints"
  type        = bool
  default     = true
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

# ---------------------------------------------------------------------------
# Control-plane scheduling
# ---------------------------------------------------------------------------

variable "enable_control_plane_taint" {
  description = "Add node-role.kubernetes.io/control-plane:NoSchedule taint to the control-plane node to prevent workload scheduling there."
  type        = bool
  default     = false
}

variable "control_plane_node_name" {
  description = "Name of the control-plane node to taint."
  type        = string
  default     = "k8s-master"
}

# ---------------------------------------------------------------------------
# AI Orchestrator
# ---------------------------------------------------------------------------

variable "enable_ai_orchestrator" {
  description = "Manage the ai-orchestrator namespace, NetworkPolicies, and ResourceQuota via Terraform. Workloads are owned by Argo CD."
  type        = bool
  default     = true
}

variable "ai_orchestrator_api_gateway_port" {
  description = "Port exposed by the api-gateway service (used in NetworkPolicy allow rule)"
  type        = number
  default     = 8080
}

variable "ai_orchestrator_cpu_request" {
  description = "Namespace ResourceQuota: total CPU requests"
  type        = string
  default     = "500m"
}

variable "ai_orchestrator_memory_request" {
  description = "Namespace ResourceQuota: total memory requests"
  type        = string
  default     = "1Gi"
}

variable "ai_orchestrator_cpu_limit" {
  description = "Namespace ResourceQuota: total CPU limits"
  type        = string
  default     = "16"
}

variable "ai_orchestrator_memory_limit" {
  description = "Namespace ResourceQuota: total memory limits"
  type        = string
  default     = "32Gi"
}

variable "ai_orchestrator_gpu_limit" {
  description = "Namespace ResourceQuota: maximum nvidia.com/gpu devices"
  type        = number
  default     = 2
}

variable "ai_orchestrator_max_pods" {
  description = "Namespace ResourceQuota: maximum pod count"
  type        = number
  default     = 20
}

variable "ai_orchestrator_max_pvcs" {
  description = "Namespace ResourceQuota: maximum PersistentVolumeClaims"
  type        = number
  default     = 10
}

# ---------------------------------------------------------------------------
# Velero backup schedules
# ---------------------------------------------------------------------------

variable "velero_create_backup_schedule" {
  description = "Create a Velero Schedule resource for automated periodic backups"
  type        = bool
  default     = true
}

variable "velero_schedule_name" {
  description = "Name of the Velero Schedule resource"
  type        = string
  default     = "daily-backup"
}

variable "velero_schedule_cron" {
  description = "Cron expression for the Velero backup schedule (UTC)"
  type        = string
  default     = "0 2 * * *" # 02:00 UTC daily
}

variable "velero_backup_namespaces" {
  description = "List of namespaces to include in each scheduled backup. Use [\"*\"] to back up all namespaces."
  type        = list(string)
  default     = ["*"]
}

variable "velero_backup_ttl" {
  description = "Retention period for backups created by the schedule (Go duration string)"
  type        = string
  default     = "720h0m0s" # 30 days
}

# Skills Dashboard Configuration
variable "enable_skills_dashboard" {
  description = "Enable the Kubernetes infrastructure skills dashboard"
  type        = bool
  default     = true
}

variable "skills_dashboard_host" {
  description = "Hostname for the skills dashboard"
  type        = string
  default     = ""
}

variable "harbor_oidc_client_id" {
  description = "OIDC client ID for Harbor"
  type        = string
  sensitive   = true
  default     = "harbor"
}

variable "harbor_oidc_client_secret" {
  description = "OIDC client secret for Harbor"
  type        = string
  sensitive   = true
  default     = ""
}

# ---------------------------------------------------------------------------
# Platform: Rancher, Traefik, MetalLB, Linkerd, KEDA
# ---------------------------------------------------------------------------

variable "enable_rancher" {
  description = "Deploy Rancher multi-cluster manager via Helm"
  type        = bool
  default     = false
}

variable "rancher_chart_version" {
  description = "Rancher Helm chart version"
  type        = string
  default     = "2.14.1"
}

variable "rancher_replicas" {
  description = "Number of Rancher server replicas"
  type        = number
  default     = 1
}

variable "enable_traefik" {
  description = "Deploy Traefik ingress controller via Helm (primary ingress controller)"
  type        = bool
  default     = false
}

variable "traefik_chart_version" {
  description = "Traefik Helm chart version"
  type        = string
  default     = "40.2.0"
}

variable "traefik_replicas" {
  description = "Number of Traefik replicas"
  type        = number
  default     = 2
}

variable "traefik_service_type" {
  description = "Traefik service type (LoadBalancer, NodePort, ClusterIP)"
  type        = string
  default     = "LoadBalancer"
}

variable "traefik_load_balancer_ip" {
  description = "Static IP for Traefik LoadBalancer service (leave empty for dynamic)"
  type        = string
  default     = ""
}

variable "enable_metallb" {
  description = "Deploy MetalLB load balancer via Helm"
  type        = bool
  default     = false
}

variable "metallb_chart_version" {
  description = "MetalLB Helm chart version"
  type        = string
  default     = "0.15.3"
}

variable "enable_linkerd" {
  description = "Manage Linkerd service mesh namespaces (control plane installed via CLI)"
  type        = bool
  default     = false
}

variable "enable_linkerd_viz" {
  description = "Whether Linkerd Viz dashboard is deployed"
  type        = bool
  default     = true
}

variable "enable_keda" {
  description = "Deploy KEDA autoscaler via Helm"
  type        = bool
  default     = false
}

variable "keda_chart_version" {
  description = "KEDA Helm chart version"
  type        = string
  default     = "2.19.0"
}

# ---------------------------------------------------------------------------
# Registry & Git: Harbor, Gitea
# ---------------------------------------------------------------------------

variable "enable_harbor" {
  description = "Deploy Harbor container registry via Helm"
  type        = bool
  default     = false
}

variable "harbor_chart_version" {
  description = "Harbor Helm chart version"
  type        = string
  default     = "1.19.0"
}

variable "harbor_ingress_class_name" {
  description = "Ingress class name for Harbor"
  type        = string
  default     = "traefik"
}

variable "harbor_admin_password" {
  description = "Harbor admin password"
  type        = string
  sensitive   = true
  default     = "Harbor12345"
}

variable "harbor_storage_class" {
  description = "Storage class for Harbor persistent volumes"
  type        = string
  default     = "local-path"
}

variable "enable_gitea" {
  description = "Deploy Gitea git server via Helm"
  type        = bool
  default     = false
}

variable "gitea_chart_version" {
  description = "Gitea Helm chart version"
  type        = string
  default     = "12.5.3"
}

variable "gitea_image_tag" {
  description = "Gitea container image tag"
  type        = string
  default     = "1.24.1"
}

variable "gitea_ingress_class_name" {
  description = "Ingress class name for Gitea"
  type        = string
  default     = "traefik"
}

variable "gitea_admin_username" {
  description = "Gitea admin username"
  type        = string
  default     = "gitea"
}

variable "gitea_admin_password" {
  description = "Gitea admin password"
  type        = string
  sensitive   = true
  default     = "gitea123"
}

variable "gitea_admin_email" {
  description = "Gitea admin email"
  type        = string
  default     = "admin@local.lan"
}

variable "gitea_postgresql_password" {
  description = "Gitea PostgreSQL password"
  type        = string
  sensitive   = true
  default     = "gitea123"
}

variable "gitea_storage_size" {
  description = "Gitea persistent volume size"
  type        = string
  default     = "20Gi"
}

variable "gitea_storage_class" {
  description = "Storage class for Gitea persistent volumes"
  type        = string
  default     = "local-path"
}

# ---------------------------------------------------------------------------
# Monitoring: Grafana Alloy
# ---------------------------------------------------------------------------

variable "enable_grafana_alloy" {
  description = "Deploy Grafana Alloy-based k8s-monitoring via Helm (replaces kube-prometheus-stack)"
  type        = bool
  default     = false
}

variable "grafana_alloy_chart_version" {
  description = "k8s-monitoring Helm chart version (Grafana Alloy)"
  type        = string
  default     = "4.1.3"
}

variable "grafana_alloy_metrics_password" {
  description = "Grafana Cloud metrics (Prometheus) API key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "grafana_alloy_logs_password" {
  description = "Grafana Cloud logs (Loki) API key"
  type        = string
  sensitive   = true
  default     = ""
}

# ---------------------------------------------------------------------------
# Rancher ecosystem: Fleet, Turtles
# ---------------------------------------------------------------------------

variable "enable_fleet" {
  description = "Deploy Rancher Fleet (GitOps at scale) via Helm"
  type        = bool
  default     = false
}

variable "fleet_chart_version" {
  description = "Fleet Helm chart version"
  type        = string
  default     = "109.0.1+up0.15.1"
}

variable "enable_rancher_turtles" {
  description = "Deploy Rancher Turtles (Cluster API integration) via Helm"
  type        = bool
  default     = false
}

variable "rancher_turtles_chart_version" {
  description = "Rancher Turtles Helm chart version"
  type        = string
  default     = "109.0.1+up0.26.1"
}

# ---------------------------------------------------------------------------
# CI/CD: Argo Workflows, Tekton
# ---------------------------------------------------------------------------

variable "enable_argo_workflows" {
  description = "Manage Argo Workflows namespace (workloads managed by Argo CD)"
  type        = bool
  default     = false
}

variable "enable_argo_events" {
  description = "Manage Argo Events namespace (workloads managed by Argo CD)"
  type        = bool
  default     = false
}

variable "enable_argo_rollouts" {
  description = "Manage Argo Rollouts namespace (workloads managed by Argo CD)"
  type        = bool
  default     = false
}

variable "enable_tekton_pipelines" {
  description = "Manage Tekton Pipelines namespace (workloads managed by Argo CD)"
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------------
# Security: Falco, Sealed Secrets
# ---------------------------------------------------------------------------

variable "enable_falco" {
  description = "Deploy Falco runtime security via Helm"
  type        = bool
  default     = false
}

variable "falco_chart_version" {
  description = "Falco Helm chart version"
  type        = string
  default     = "8.0.2"
}

variable "enable_sealed_secrets" {
  description = "Deploy Sealed Secrets controller for GitOps-friendly secret encryption"
  type        = bool
  default     = false
}

variable "sealed_secrets_image" {
  description = "Sealed Secrets controller image"
  type        = string
  default     = "docker.io/bitnami/sealed-secrets-controller:v0.24.1"
}

# ---------------------------------------------------------------------------
# Build & Apps: BuildKit, Sabnzbd, Website Tracker
# ---------------------------------------------------------------------------

variable "enable_buildkit" {
  description = "Manage BuildKit namespace (workload managed by Argo CD)"
  type        = bool
  default     = false
}

variable "enable_sabnzbd" {
  description = "Manage Sabnzbd namespace (workload managed by Argo CD)"
  type        = bool
  default     = false
}

variable "enable_website_tracker" {
  description = "Deploy Website Tracker operator via Helm"
  type        = bool
  default     = false
}

variable "website_tracker_chart_version" {
  description = "Website Tracker Helm chart version"
  type        = string
  default     = "0.1.0"
}
