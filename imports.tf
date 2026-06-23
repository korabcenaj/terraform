################################################################################
# Terraform Import Blocks (Terraform 1.5+)
# Import cluster resources that already exist so Terraform manages them
################################################################################

# Namespaces
import {
  to = module.cert_manager[0].kubernetes_namespace.cert_manager
  id = "cert-manager"
}

import {
  to = module.keda[0].kubernetes_namespace.keda
  id = "keda"
}

import {
  to = module.traefik[0].kubernetes_namespace.traefik
  id = "traefik"
}

import {
  to = module.tempo[0].kubernetes_namespace.tracing
  id = "tracing"
}

import {
  to = kubernetes_namespace.portfolio[0]
  id = "portfolio"
}

import {
  to = kubernetes_namespace.jellyfin[0]
  id = "jellyfin"
}

import {
  to = kubernetes_namespace.pihole[0]
  id = "pihole"
}

import {
  to = kubernetes_namespace.ci_builds
  id = "ci-builds"
}

# Helm releases
import {
  to = module.cert_manager[0].helm_release.cert_manager[0]
  id = "cert-manager/cert-manager"
}

import {
  to = module.keda[0].helm_release.keda
  id = "keda/keda"
}

import {
  to = module.traefik[0].helm_release.traefik
  id = "traefik/traefik"
}

import {
  to = module.tempo[0].helm_release.tempo
  id = "tracing/tempo"
}

import {
  to = module.oauth2_proxy[0].helm_release.oauth2_proxy
  id = "oauth2-proxy/oauth2-proxy"
}


# ===========================================================================
# Direct resource imports — existing deployments brought under management
# ===========================================================================

# --- MinIO (plain k8s, not Helm) ---

import {
  to = kubernetes_namespace.minio_direct[0]
  id = "minio"
}

import {
  to = kubernetes_secret_v1.minio_credentials[0]
  id = "minio/minio-credentials"
}

import {
  to = kubernetes_persistent_volume_claim_v1.minio_data[0]
  id = "minio/minio-data-longhorn"
}

import {
  to = kubernetes_deployment_v1.minio[0]
  id = "minio/minio"
}

import {
  to = kubernetes_service_v1.minio[0]
  id = "minio/minio"
}

import {
  to = kubernetes_service_v1.minio_external[0]
  id = "minio/minio-external"
}

# --- Gitea Actions Runner ---

import {
  to = kubernetes_namespace.gitea_runner[0]
  id = "gitea-runner"
}

import {
  to = kubernetes_config_map_v1.gitea_runner_config[0]
  id = "gitea-runner/gitea-runner-config"
}

import {
  to = kubernetes_secret_v1.gitea_runner_token[0]
  id = "gitea-runner/gitea-runner-token"
}

import {
  to = kubernetes_persistent_volume_claim_v1.gitea_runner_data[0]
  id = "gitea-runner/gitea-runner-data-longhorn"
}

import {
  to = kubernetes_deployment_v1.gitea_runner[0]
  id = "gitea-runner/gitea-runner"
}

import {
  to = kubernetes_cluster_role_v1.gitea_runner_cr[0]
  id = "gitea-runner"
}

# --- qBittorrent ---

import {
  to = kubernetes_namespace.qbittorrent[0]
  id = "qbittorrent"
}

import {
  to = kubernetes_persistent_volume_claim_v1.qbittorrent_config[0]
  id = "qbittorrent/qbittorrent-config-pvc"
}

import {
  to = kubernetes_deployment_v1.qbittorrent[0]
  id = "qbittorrent/qbittorrent"
}

import {
  to = kubernetes_service_v1.qbittorrent[0]
  id = "qbittorrent/qbittorrent"
}

import {
  to = kubernetes_ingress_v1.qbittorrent[0]
  id = "qbittorrent/qbittorrent"
}

# --- local-path-storage ---

import {
  to = kubernetes_namespace.local_path_storage[0]
  id = "local-path-storage"
}

import {
  to = kubernetes_config_map_v1.local_path_config[0]
  id = "local-path-storage/local-path-config"
}

import {
  to = kubernetes_service_account_v1.local_path_provisioner_sa[0]
  id = "local-path-storage/local-path-provisioner-service-account"
}

import {
  to = kubernetes_cluster_role_v1.local_path_provisioner_cr[0]
  id = "local-path-provisioner-role"
}

import {
  to = kubernetes_cluster_role_binding_v1.local_path_provisioner_crb[0]
  id = "local-path-provisioner-bind"
}

import {
  to = kubernetes_deployment_v1.local_path_provisioner[0]
  id = "local-path-storage/local-path-provisioner"
}

# --- Portfolio preview environments ---

import {
  to = kubernetes_namespace.portfolio_dev[0]
  id = "portfolio-dev"
}

import {
  to = kubernetes_deployment_v1.portfolio_dev_web[0]
  id = "portfolio-dev/portfolio-web"
}

import {
  to = kubernetes_service_v1.portfolio_dev_web[0]
  id = "portfolio-dev/portfolio-web"
}

import {
  to = kubernetes_ingress_v1.portfolio_dev_web[0]
  id = "portfolio-dev/portfolio-web"
}

import {
  to = kubernetes_namespace.portfolio_stage[0]
  id = "portfolio-stage"
}

import {
  to = kubernetes_deployment_v1.portfolio_stage_web[0]
  id = "portfolio-stage/portfolio-web"
}

import {
  to = kubernetes_service_v1.portfolio_stage_web[0]
  id = "portfolio-stage/portfolio-web"
}

import {
  to = kubernetes_ingress_v1.portfolio_stage_web[0]
  id = "portfolio-stage/portfolio-web"
}
