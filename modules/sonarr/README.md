# Sonarr Terraform Module

This module deploys Sonarr via Helm on Kubernetes. It exposes all major Helm values for customization.

## Example Usage

```hcl
module "sonarr" {
  source        = "./modules/sonarr"
  namespace     = "media"
  chart_version = "16.2.2"
  persistence = {
    config = {
      enabled = true
      size    = "5Gi"
    }
  }
  ingress = {
    enabled = true
    hosts = ["sonarr.example.com"]
  }
  resources = {
    requests = { cpu = "100m", memory = "256Mi" }
    limits   = { cpu = "500m", memory = "512Mi" }
  }
  jellyfin_service_endpoint     = module.jellyfin.service_endpoint
  qbittorrent_service_endpoint  = module.qbittorrent.service_endpoint
}
```

## Variables
- `namespace` (string): Namespace to deploy Sonarr
- `chart_version` (string): Helm chart version
- `persistence` (map): Persistence config
- `ingress` (map): Ingress config
- `resources` (map): Resource requests/limits
- `service` (map): Service config
- `jellyfin_service_endpoint` (string): Jellyfin service endpoint (host:port) for integration
- `qbittorrent_service_endpoint` (string): qBittorrent service endpoint (host:port) for integration
- `securityContext`, `nodeSelector`, `affinity`, `tolerations`, `extraEnv`, `extraVolumes`, `extraVolumeMounts`, `labels`, `annotations` (all optional)

## Outputs
- `sonarr_name`: Helm release name
