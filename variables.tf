# Sonarr
variable "enable_sonarr" {
  description = "Enable Sonarr application"
  type        = bool
  default     = false
}

variable "sonarr_chart_version" {
  description = "Sonarr Helm chart version"
  type        = string
  default     = "16.2.2"
}

# Radarr
variable "enable_radarr" {
  description = "Enable Radarr application"
  type        = bool
  default     = false
}

variable "radarr_chart_version" {
  description = "Radarr Helm chart version"
  type        = string
  default     = "16.2.2"
}
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

variable "enable_gpu_priority_classes" {
  description = "Create PriorityClass resources for interactive and batch GPU workloads"
  type        = bool
  default     = false
}

variable "gpu_interactive_priority_name" {
  description = "PriorityClass name for interactive GPU workloads"
  type        = string
  default     = "gpu-interactive-high"
}

variable "gpu_interactive_priority_value" {
  description = "PriorityClass value for interactive GPU workloads"
  type        = number
  default     = 100000
}

variable "gpu_batch_priority_name" {
  description = "PriorityClass name for batch GPU workloads"
  type        = string
  default     = "gpu-batch-low"
}

variable "gpu_batch_priority_value" {
  description = "PriorityClass value for batch GPU workloads"
  type        = number
  default     = 10000
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

variable "enable_slo_alerts" {
  description = "Create PrometheusRule alerts for portfolio SLO burn-rate and latency"
  type        = bool
  default     = false
}

variable "alertmanager_incident_webhook_url" {
  description = "Optional webhook URL for Alertmanager incident routing (Slack/Discord relay, bot, or webhook service)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "alertmanager_incident_minimum_severity" {
  description = "Alert severity matcher routed to the incident webhook"
  type        = string
  default     = "critical"
}

variable "alertmanager_incident_send_resolved" {
  description = "Whether Alertmanager sends resolved notifications to the incident webhook"
  type        = bool
  default     = true
}

variable "slo_portfolio_availability_target_percent" {
  description = "Portfolio availability SLO target percentage"
  type        = number
  default     = 99

  validation {
    condition     = var.slo_portfolio_availability_target_percent > 0 && var.slo_portfolio_availability_target_percent < 100
    error_message = "slo_portfolio_availability_target_percent must be > 0 and < 100."
  }
}

variable "slo_portfolio_latency_p95_seconds" {
  description = "Portfolio p95 latency SLO threshold in seconds"
  type        = number
  default     = 1

  validation {
    condition     = var.slo_portfolio_latency_p95_seconds > 0
    error_message = "slo_portfolio_latency_p95_seconds must be > 0."
  }
}

variable "slo_prometheus_release_label" {
  description = "Prometheus release selector label value used by kube-prometheus-stack"
  type        = string
  default     = "monitor"
}

variable "bootstrap_namespaces" {
  description = "Generic namespace bootstrap definitions for future apps with baseline security and quotas"
  type = map(object({
    pod_security_enforce   = optional(string)
    pod_security_audit     = optional(string)
    pod_security_warn      = optional(string)
    pod_limit              = optional(string)
    cpu_request_quota      = optional(string)
    memory_request_quota   = optional(string)
    cpu_limit_quota        = optional(string)
    memory_limit_quota     = optional(string)
    default_cpu_request    = optional(string)
    default_memory_request = optional(string)
    default_cpu_limit      = optional(string)
    default_memory_limit   = optional(string)
    create_default_deny    = optional(bool)
  }))
  default = {}
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

variable "enable_argo_rollouts" {
  description = "Deploy Argo Rollouts controller for progressive delivery"
  type        = bool
  default     = false
}

variable "argo_rollouts_chart_version" {
  description = "Argo Rollouts Helm chart version"
  type        = string
  default     = "2.39.5"
}

variable "argo_rollouts_dashboard_enabled" {
  description = "Enable Argo Rollouts dashboard service"
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

variable "enable_portfolio_rollout_metric_gates" {
  description = "Create an AnalysisTemplate for portfolio rollout promotion/rollback checks"
  type        = bool
  default     = false
}

variable "portfolio_rollout_metrics_prometheus_address" {
  description = "Prometheus address used by Argo Rollouts AnalysisTemplate"
  type        = string
  default     = "http://monitor-kube-prometheus-st-prometheus.monitoring.svc.cluster.local:9090"
}

variable "portfolio_rollout_success_rate_minimum_percent" {
  description = "Minimum success rate percentage required by rollout analysis"
  type        = number
  default     = 99

  validation {
    condition     = var.portfolio_rollout_success_rate_minimum_percent > 0 && var.portfolio_rollout_success_rate_minimum_percent <= 100
    error_message = "portfolio_rollout_success_rate_minimum_percent must be > 0 and <= 100."
  }
}

variable "portfolio_rollout_latency_p95_threshold_seconds" {
  description = "Maximum p95 latency in seconds allowed during rollout analysis"
  type        = number
  default     = 1

  validation {
    condition     = var.portfolio_rollout_latency_p95_threshold_seconds > 0
    error_message = "portfolio_rollout_latency_p95_threshold_seconds must be > 0."
  }
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

  validation {
    condition     = contains(["Audit", "Enforce"], var.kyverno_enforcement_mode)
    error_message = "kyverno_enforcement_mode must be either 'Audit' or 'Enforce'."
  }
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
