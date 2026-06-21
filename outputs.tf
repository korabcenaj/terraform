output "cluster_name" {
  description = "Kubernetes cluster name"
  value       = var.cluster_name
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "portfolio_namespace" {
  description = "Portfolio application namespace"
  value       = try(kubernetes_namespace.portfolio[0].metadata[0].name, null)
  depends_on  = [module.portfolio]
}

output "jellyfin_namespace" {
  description = "Jellyfin media server namespace"
  value       = try(kubernetes_namespace.jellyfin[0].metadata[0].name, null)
  depends_on  = [module.jellyfin]
}

output "loki_namespace" {
  description = "Loki logging namespace"
  value       = try(module.loki[0].namespace, null)
}

output "minio_namespace" {
  description = "MinIO storage namespace"
  value       = try(module.minio[0].namespace, null)
}

output "velero_namespace" {
  description = "Velero backup namespace"
  value       = try(module.velero[0].namespace, null)
}

output "vault_namespace" {
  description = "Vault namespace"
  value       = try(module.vault[0].namespace, null)
}

output "external_secrets_namespace" {
  description = "External Secrets namespace"
  value       = try(module.external_secrets[0].namespace, null)
}

output "tempo_namespace" {
  description = "Tempo tracing namespace"
  value       = try(module.tempo[0].namespace, null)
}

output "keycloak_namespace" {
  description = "Keycloak namespace"
  value       = try(module.keycloak_light[0].namespace, null)
}

output "matrix_synapse_namespace" {
  description = "Matrix Synapse namespace"
  value       = try(module.matrix_synapse[0].namespace, null)
}


output "portfolio_service" {
  description = "Portfolio service information"
  value = try({
    name      = "portfolio-web"
    namespace = kubernetes_namespace.portfolio[0].metadata[0].name
    type      = "ClusterIP"
    port      = 80
  }, null)
}

output "jellyfin_service" {
  description = "Jellyfin service information"
  value = try({
    name      = "jellyfin"
    namespace = kubernetes_namespace.jellyfin[0].metadata[0].name
    type      = "ClusterIP"
    port      = 8096
  }, null)
}

output "ingress_urls" {
  description = "Primary ingress URLs derived from the configured ingress base domain"
  value = {
    portfolio    = "https://portfolio.${var.ingress_base_domain}"
    jellyfin     = "https://jellyfin.${var.ingress_base_domain}"
    pihole       = "https://pihole.${var.ingress_base_domain}"
    grafana      = "https://grafana.${var.ingress_base_domain}"
    minio        = "https://minio.${var.ingress_base_domain}"
    vault        = "https://vault.${var.ingress_base_domain}"
    keycloak     = "https://sso.${var.ingress_base_domain}"
    oauth2_proxy = "https://auth.${var.ingress_base_domain}"
    matrix       = "https://${local.matrix_synapse_host}"
    dendrite     = "https://${local.matrix_dendrite_host}"
    awx          = "https://awx.${var.ingress_base_domain}"
  }
}

output "deployed_modules" {
  description = "Deployed modules summary"
  value = {
    portfolio         = var.enable_portfolio
    jellyfin          = var.enable_jellyfin
    pihole            = var.enable_pihole
    monitoring        = var.enable_monitoring
    loki              = var.enable_loki
    minio             = var.enable_minio
    velero            = var.enable_velero
    vault             = var.enable_vault
    external_secrets  = var.enable_external_secrets
    tempo             = var.enable_tempo
    keycloak          = var.enable_keycloak_light
    matrix_synapse    = var.enable_matrix_synapse
    matrix_dendrite   = var.enable_matrix_dendrite
    cloudflare_tunnel = var.enable_cloudflare_tunnel
    oauth2_proxy      = var.enable_oauth2_proxy
    kyverno           = var.enable_kyverno
    metrics_server    = var.enable_metrics_server
    network_policies  = var.enable_network_policies
    awx               = var.enable_awx
  }
}

output "metrics_server_release" {
  description = "Metrics-server deployment name"
  value       = try(module.metrics_server[0].release_name, null)
}

output "loki_release" {
  description = "Loki Helm release name"
  value       = try(module.loki[0].release_name, null)
}

output "minio_release" {
  description = "MinIO Helm release name"
  value       = try(module.minio[0].release_name, null)
}

output "velero_release" {
  description = "Velero Helm release name"
  value       = try(module.velero[0].release_name, null)
}

output "vault_release" {
  description = "Vault Helm release name"
  value       = try(module.vault[0].release_name, null)
}

output "external_secrets_release" {
  description = "External Secrets Helm release name"
  value       = try(module.external_secrets[0].release_name, null)
}

output "tempo_release" {
  description = "Tempo Helm release name"
  value       = try(module.tempo[0].release_name, null)
}

output "keycloak_release" {
  description = "Keycloak deployment name"
  value       = try(module.keycloak_light[0].release_name, null)
}

output "matrix_synapse_name" {
  description = "Matrix Synapse deployment/service base name"
  value       = try(module.matrix_synapse[0].name, null)
}

output "matrix_synapse_ingress_host" {
  description = "Matrix Synapse ingress host"
  value       = try(module.matrix_synapse[0].ingress_host, null)
}

output "matrix_synapse_public_base_url" {
  description = "Matrix Synapse public base URL"
  value       = try(module.matrix_synapse[0].public_base_url, null)
}

output "matrix_synapse_oidc_enabled" {
  description = "Whether Matrix Synapse OIDC is enabled"
  value       = var.matrix_synapse_oidc_enabled
}

output "matrix_synapse_federation_enabled" {
  description = "Whether Matrix Synapse federation is enabled"
  value       = var.matrix_synapse_federation_enabled
}

output "matrix_dendrite_namespace" {
  description = "Matrix Dendrite namespace"
  value       = try(module.matrix_dendrite[0].namespace, null)
}

output "matrix_dendrite_name" {
  description = "Matrix Dendrite deployment/service base name"
  value       = try(module.matrix_dendrite[0].name, null)
}

output "matrix_dendrite_ingress_host" {
  description = "Matrix Dendrite ingress host"
  value       = try(module.matrix_dendrite[0].ingress_host, null)
}

output "matrix_dendrite_public_base_url" {
  description = "Matrix Dendrite public base URL"
  value       = try(module.matrix_dendrite[0].public_base_url, null)
}

output "matrix_dendrite_oidc_enabled" {
  description = "Whether Matrix Dendrite OIDC is enabled"
  value       = var.matrix_dendrite_oidc_enabled
}

output "matrix_dendrite_federation_enabled" {
  description = "Whether Matrix Dendrite federation is enabled"
  value       = var.matrix_dendrite_federation_enabled
}

output "keycloak_base_url" {
  description = "Local Keycloak base URL"
  value       = try(module.keycloak_light[0].base_url, "https://sso.${var.ingress_base_domain}")
}

output "keycloak_issuer_url" {
  description = "Expected OIDC issuer URL for the default realm"
  value       = try(module.keycloak_light[0].issuer_url, "https://sso.${var.ingress_base_domain}/realms/${var.keycloak_light_realm}")
}

output "native_oidc_apps" {
  description = "Applications configured to use native OIDC instead of ingress-wide forward-auth"
  value = {
    grafana = var.enable_grafana_oidc
  }
}

output "oauth2_proxy_namespace" {
  description = "OAuth2 Proxy namespace"
  value       = try(module.oauth2_proxy[0].namespace, null)
}

output "oauth2_proxy_release" {
  description = "OAuth2 Proxy Helm release name"
  value       = try(module.oauth2_proxy[0].release_name, null)
}

output "oauth2_proxy_auth_url" {
  description = "Traefik Middleware annotation value for protecting ingresses with OAuth2 Proxy forward-auth"
  value       = try(module.oauth2_proxy[0].auth_url, "oauth2-proxy-forward-auth@kubernetescrd")
}

output "oauth2_proxy_signin_url" {
  description = "OAuth2 Proxy sign-in URL for redirecting unauthenticated users"
  value       = try(module.oauth2_proxy[0].signin_url, "https://auth.${var.ingress_base_domain}/oauth2/start?rd=$escaped_request_uri")
}

output "kyverno_namespace" {
  description = "Kyverno namespace"
  value       = try(module.kyverno[0].namespace, null)
}

output "kyverno_release" {
  description = "Kyverno Helm release name"
  value       = try(module.kyverno[0].release_name, null)
}

output "kyverno_enforcement_mode" {
  description = "Active Kyverno enforcement mode"
  value       = try(module.kyverno[0].enforcement_mode, null)
}

# ---------------------------------------------------------------------------
# Platform outputs
# ---------------------------------------------------------------------------

output "rancher_namespace" {
  description = "Rancher namespace"
  value       = try(module.rancher[0].namespace, null)
}

output "traefik_namespace" {
  description = "Traefik namespace"
  value       = try(module.traefik[0].namespace, null)
}

output "linkerd_namespace" {
  description = "Linkerd namespace"
  value       = try(module.linkerd[0].namespace, null)
}

output "keda_namespace" {
  description = "KEDA namespace"
  value       = try(module.keda[0].namespace, null)
}

# ---------------------------------------------------------------------------
# Registry & Git outputs
# ---------------------------------------------------------------------------

output "harbor_namespace" {
  description = "Harbor namespace"
  value       = try(module.harbor[0].namespace, null)
}

output "harbor_ingress_host" {
  description = "Harbor ingress hostname"
  value       = try(module.harbor[0].ingress_host, null)
}

output "gitea_namespace" {
  description = "Gitea namespace"
  value       = try(module.gitea[0].namespace, null)
}

output "gitea_ingress_host" {
  description = "Gitea ingress hostname"
  value       = try(module.gitea[0].ingress_host, null)
}

# ---------------------------------------------------------------------------
# Rancher ecosystem outputs
# ---------------------------------------------------------------------------

output "fleet_release" {
  description = "Fleet Helm release name"
  value       = try(module.fleet[0].release_name, null)
}

output "rancher_turtles_release" {
  description = "Rancher Turtles Helm release name"
  value       = try(module.rancher_turtles[0].release_name, null)
}

# ---------------------------------------------------------------------------
# CI/CD outputs
# ---------------------------------------------------------------------------

output "argo_workflows_namespace" {
  description = "Argo Workflows namespace"
  value       = try(module.argo_workflows[0].argo_namespace, null)
}

output "argo_events_namespace" {
  description = "Argo Events namespace"
  value       = try(module.argo_workflows[0].argo_events_namespace, null)
}

output "argo_rollouts_namespace" {
  description = "Argo Rollouts namespace"
  value       = try(module.argo_workflows[0].argo_rollouts_namespace, null)
}

output "tekton_pipelines_namespace" {
  description = "Tekton Pipelines namespace"
  value       = try(module.tekton_pipelines[0].pipelines_namespace, null)
}

# ---------------------------------------------------------------------------
# Security outputs
# ---------------------------------------------------------------------------

output "falco_namespace" {
  description = "Falco namespace"
  value       = try(module.falco[0].namespace, null)
}

output "sealed_secrets_deployment" {
  description = "Sealed Secrets deployment name"
  value       = try(module.sealed_secrets[0].deployment_name, null)
}

# ---------------------------------------------------------------------------
# Build & Apps outputs
# ---------------------------------------------------------------------------

output "buildkit_namespace" {
  description = "BuildKit namespace"
  value       = try(module.buildkit[0].namespace, null)
}

output "sabnzbd_namespace" {
  description = "Sabnzbd namespace"
  value       = try(module.sabnzbd[0].namespace, null)
}

# ---------------------------------------------------------------------------
# Automation (AWX / Ansible) outputs
# ---------------------------------------------------------------------------

output "awx_namespace" {
  description = "AWX namespace"
  value       = try(module.awx[0].namespace, null)
}

output "awx_ingress_url" {
  description = "AWX web UI URL"
  value       = try(module.awx[0].ingress_url, null)
}

output "awx_admin_user" {
  description = "AWX admin username"
  value       = try(module.awx[0].admin_user, null)
}

output "awx_admin_password_cmd" {
  description = "Command to retrieve the auto-generated AWX admin password from the cluster"
  value       = var.enable_awx && trimspace(var.awx_admin_password) == "" ? "kubectl get secret awx-admin-password -n awx -o jsonpath='{.data.password}' | base64 -d" : null
  sensitive   = true
}
