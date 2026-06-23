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
  default     = "192.168.0.210"

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
  description = "Enable monitoring stack (ingress + network policies for existing VictoriaMetrics/Grafana)"
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

variable "enable_tempo" {
  description = "Deploy Grafana Tempo via Helm for distributed tracing"
  type        = bool
  default     = false
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
  default     = "2.5.0"
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

# Application configurations
variable "portfolio_replicas" {
  description = "Number of portfolio replicas (ignored when KEDA is enabled)"
  type        = number
  default     = 1
}

variable "portfolio_image" {
  description = "Container image for portfolio web app"
  type        = string
  default     = "nginxinc/nginx-unprivileged:1.29-alpine"
}

variable "portfolio_image_pull_secrets" {
  description = "List of image pull secret names for portfolio"
  type        = list(string)
  default     = []
}

variable "jellyfin_replicas" {
  description = "Number of jellyfin replicas"
  type        = number
  default     = 1
}

# Storage
variable "jellyfin_storage_class" {
  description = "Storage class for Jellyfin data (config + cache). Media uses its own PVC (see jellyfin_media_pvc_name)."
  type        = string
  default     = "longhorn"
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

variable "jellyfin_gpu_count" {
  description = "Number of AMD GPUs for Jellyfin hardware transcoding (0 disables GPU)"
  type        = number
  default     = 1
}

variable "jellyfin_media_path" {
  description = "Host path for Jellyfin media files (used for hostPath PV; ignored when media_pvc_name is set)"
  type        = string
  default     = "/media/library"
}

variable "jellyfin_media_pvc_name" {
  description = "Name of an existing PVC to use for Jellyfin media. Leave empty to use hostPath (jellyfin_media_path). Set to a PVC name (e.g. 'jellyfin-media-pvc-longhorn') once enough Longhorn disk space is available."
  type        = string
  default     = ""
}

variable "jellyfin_load_balancer_ip" {
  description = "External IP for Jellyfin LoadBalancer service"
  type        = string
  default     = "192.168.0.209"
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
  default     = "3.8.1"
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
# Local identity provider — lightweight Keycloak (Quarkus, H2 embedded DB, no PostgreSQL)
# ---------------------------------------------------------------------------

variable "enable_keycloak_light" {
  description = "Deploy a lightweight Keycloak identity provider (Quarkus-based, H2 embedded database)"
  type        = bool
  default     = false
}

variable "keycloak_light_image" {
  description = "Keycloak container image (official Quarkus distribution)"
  type        = string
  default     = "quay.io/keycloak/keycloak:26.1"
}

variable "keycloak_light_admin_user" {
  description = "Keycloak bootstrap admin username"
  type        = string
  default     = "admin"
}

variable "keycloak_light_admin_password" {
  description = "Keycloak bootstrap admin password"
  type        = string
  sensitive   = true
  default     = "CHANGE_ME_KEYCLOAK_ADMIN_PASSWORD"
}

variable "keycloak_light_realm" {
  description = "Default realm name for OIDC clients (created manually after first login)"
  type        = string
  default     = "homelab"
}

variable "keycloak_light_storage_class" {
  description = "Storage class for the Keycloak H2 data volume"
  type        = string
  default     = "local-path"
}

variable "keycloak_light_storage_size" {
  description = "Persistent volume size for the Keycloak H2 database"
  type        = string
  default     = "2Gi"
}

variable "keycloak_light_cpu_request" {
  description = "CPU request for Keycloak"
  type        = string
  default     = "100m"
}

variable "keycloak_light_memory_request" {
  description = "Memory request for Keycloak"
  type        = string
  default     = "256Mi"
}

variable "keycloak_light_cpu_limit" {
  description = "CPU limit for Keycloak"
  type        = string
  default     = "500m"
}

variable "keycloak_light_memory_limit" {
  description = "Memory limit for Keycloak"
  type        = string
  default     = "512Mi"
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

# ---------------------------------------------------------------------------
# Matrix Dendrite (Go-based, lightweight alternative to Synapse)
# ---------------------------------------------------------------------------

variable "enable_matrix_dendrite" {
  description = "Deploy Matrix Dendrite chat server (Go-based, ~50-80 MB RAM vs Synapse's ~172 MB)"
  type        = bool
  default     = false
}

variable "matrix_dendrite_image" {
  description = "Container image for Matrix Dendrite monolith"
  type        = string
  default     = "matrixdotorg/dendrite-monolith:v0.14.1"
}

variable "matrix_dendrite_server_name" {
  description = "Optional explicit Matrix server_name used for user IDs and federation. Leave empty to use chat.<ingress_base_domain>."
  type        = string
  default     = ""
}

variable "matrix_dendrite_public_base_url" {
  description = "Optional explicit public base URL for Dendrite. Leave empty to use https://chat.<ingress_base_domain>."
  type        = string
  default     = ""
}

variable "matrix_dendrite_ingress_host" {
  description = "Optional explicit ingress host for Matrix Dendrite. Leave empty to use chat.<ingress_base_domain>."
  type        = string
  default     = ""
}

variable "matrix_dendrite_cluster_issuer" {
  description = "cert-manager ClusterIssuer used by Matrix Dendrite ingress TLS"
  type        = string
  default     = "local-lan-ca"
}

variable "matrix_dendrite_storage_size" {
  description = "Persistent volume size for Matrix Dendrite data"
  type        = string
  default     = "20Gi"
}

variable "matrix_dendrite_storage_class" {
  description = "Storage class for Matrix Dendrite persistent volume"
  type        = string
  default     = "local-path"
}

variable "matrix_dendrite_cpu_request" {
  description = "CPU request for Matrix Dendrite"
  type        = string
  default     = "100m"
}

variable "matrix_dendrite_memory_request" {
  description = "Memory request for Matrix Dendrite"
  type        = string
  default     = "128Mi"
}

variable "matrix_dendrite_cpu_limit" {
  description = "CPU limit for Matrix Dendrite"
  type        = string
  default     = "500m"
}

variable "matrix_dendrite_memory_limit" {
  description = "Memory limit for Matrix Dendrite"
  type        = string
  default     = "512Mi"
}

variable "matrix_dendrite_registration_shared_secret" {
  description = "Shared secret used for controlled user provisioning via Dendrite create-account"
  type        = string
  sensitive   = true
  default     = "CHANGE_ME_MATRIX_DENDRITE_SHARED_SECRET"
}

variable "matrix_dendrite_bootstrap_admin_enabled" {
  description = "Run one-shot Kubernetes Job to create the first Matrix Dendrite admin user"
  type        = bool
  default     = false
}

variable "matrix_dendrite_bootstrap_admin_username" {
  description = "Username for first Matrix Dendrite admin account"
  type        = string
  default     = "admin"
}

variable "matrix_dendrite_bootstrap_admin_password" {
  description = "Password for first Matrix Dendrite admin account"
  type        = string
  sensitive   = true
  default     = ""
}

variable "matrix_dendrite_oidc_enabled" {
  description = "Enable OIDC login for Matrix Dendrite"
  type        = bool
  default     = false
}

variable "matrix_dendrite_oidc_issuer_url" {
  description = "Optional explicit OIDC issuer URL. Leave empty to use Keycloak realm URL derived from ingress_base_domain and keycloak_realm."
  type        = string
  default     = ""
}

variable "matrix_dendrite_oidc_client_id" {
  description = "OIDC client ID for Matrix Dendrite"
  type        = string
  default     = "matrix-dendrite"
}

variable "matrix_dendrite_oidc_client_secret" {
  description = "OIDC client secret for Matrix Dendrite"
  type        = string
  sensitive   = true
  default     = ""
}

variable "matrix_dendrite_oidc_scopes" {
  description = "OIDC scopes requested by Matrix Dendrite"
  type        = list(string)
  default     = ["openid", "profile", "email"]
}

variable "matrix_dendrite_federation_enabled" {
  description = "Enable Matrix federation with external homeservers"
  type        = bool
  default     = false
}

variable "matrix_dendrite_federation_domain_whitelist" {
  description = "Optional allow-list of external homeserver domains for federation. Empty means unrestricted when federation is enabled."
  type        = list(string)
  default     = []
}

variable "matrix_dendrite_well_known_enabled" {
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
# Networking: Cilium CNI
# ---------------------------------------------------------------------------

variable "enable_cilium" {
  description = "Manage the Cilium CNI Helm release via Terraform"
  type        = bool
  default     = false
}

variable "cilium_chart_version" {
  description = "Cilium Helm chart version"
  type        = string
  default     = "1.19.4"
}

variable "cilium_k8s_api_host" {
  description = "Kubernetes API server IP that Cilium should connect to"
  type        = string
  default     = "192.168.0.83"
}

# ---------------------------------------------------------------------------
# Load Balancing: MetalLB
# ---------------------------------------------------------------------------

variable "enable_metallb" {
  description = "Manage the MetalLB Helm release via Terraform"
  type        = bool
  default     = false
}

variable "metallb_chart_version" {
  description = "MetalLB Helm chart version"
  type        = string
  default     = "0.15.3"
}

# ---------------------------------------------------------------------------
# Storage: Longhorn
# ---------------------------------------------------------------------------

variable "enable_longhorn" {
  description = "Manage the Longhorn distributed storage Helm release via Terraform"
  type        = bool
  default     = false
}

variable "longhorn_chart_version" {
  description = "Longhorn Helm chart version"
  type        = string
  default     = "1.12.0"
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
  default     = "0.15.2"
}

variable "enable_rancher_turtles" {
  description = "Deploy Rancher Turtles (Cluster API integration) via Helm"
  type        = bool
  default     = false
}

variable "rancher_turtles_chart_version" {
  description = "Rancher Turtles Helm chart version"
  type        = string
  default     = "0.26.2"
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

# ---------------------------------------------------------------------------
# Ansible Automation Platform (AWX)
# ---------------------------------------------------------------------------

variable "enable_awx" {
  description = "Deploy AWX (Ansible Automation Platform upstream) via the AWX Operator on Kubernetes"
  type        = bool
  default     = false
}

variable "awx_operator_chart_version" {
  description = "AWX Operator Helm chart version"
  type        = string
  default     = "2.19.1"
}

variable "awx_image_version" {
  description = "AWX container image version tag"
  type        = string
  default     = "24.6.1"
}

variable "awx_admin_user" {
  description = "AWX admin username"
  type        = string
  default     = "admin"
}

variable "awx_admin_password" {
  description = "AWX admin password (leave empty to auto-generate via the operator; retrieve with kubectl get secret awx-admin-password -n awx)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "awx_admin_email" {
  description = "AWX admin email"
  type        = string
  default     = "admin@local.lan"
}

variable "awx_web_replicas" {
  description = "Number of AWX web UI replicas"
  type        = number
  default     = 1
}

variable "awx_task_replicas" {
  description = "Number of AWX background task replicas"
  type        = number
  default     = 1
}

variable "awx_postgres_storage_size" {
  description = "Persistent volume size for AWX PostgreSQL"
  type        = string
  default     = "10Gi"
}

variable "awx_postgres_storage_class" {
  description = "Storage class for AWX PostgreSQL persistent volume"
  type        = string
  default     = "local-path"
}

# ---------------------------------------------------------------------------
# Ansible node management (playbook-driven)
# ---------------------------------------------------------------------------

variable "ansible_node_ips" {
  description = "Map of node hostnames to IPs used by the Ansible inventory"
  type        = map(string)
  default = {
    "k8s-master" = "192.168.0.83"
    "k8s"        = "192.168.0.107"
    "k8s2"       = "192.168.0.159"
  }
}

# ---------------------------------------------------------------------------
# Directly managed resources — existing deployments imported into Terraform
# (non-Helm, created outside Terraform, now brought under management)
# ---------------------------------------------------------------------------

variable "enable_minio_direct" {
  description = "Manage existing non-Helm MinIO deployment (plain k8s, not the Helm module)"
  type        = bool
  default     = false
}

variable "enable_gitea_runner" {
  description = "Manage existing Gitea Actions runner deployment"
  type        = bool
  default     = false
}

variable "enable_qbittorrent" {
  description = "Manage existing qBittorrent deployment"
  type        = bool
  default     = false
}

variable "enable_local_path_storage" {
  description = "Manage existing local-path-storage provisioner"
  type        = bool
  default     = false
}

variable "enable_portfolio_dev" {
  description = "Manage existing portfolio-dev preview environment"
  type        = bool
  default     = false
}

variable "enable_portfolio_stage" {
  description = "Manage existing portfolio-stage preview environment"
  type        = bool
  default     = false
}
