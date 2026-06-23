# ===========================================================================
# Resource Quotas — Prevent resource exhaustion in application namespaces
# ===========================================================================

resource "kubernetes_resource_quota" "portfolio" {
  count = var.enable_portfolio_quota ? 1 : 0

  metadata {
    name      = "portfolio-quota"
    namespace = var.portfolio_namespace
    labels = merge(var.tags, { app = "portfolio" })
  }

  spec {
    hard = {
      "pods"                   = "10"
      "requests.cpu"           = "2"
      "requests.memory"        = "2Gi"
      "limits.cpu"             = "4"
      "limits.memory"          = "4Gi"
      "persistentvolumeclaims" = "5"
    }
  }
}

resource "kubernetes_resource_quota" "jellyfin" {
  count = var.enable_jellyfin_quota ? 1 : 0

  metadata {
    name      = "jellyfin-quota"
    namespace = var.jellyfin_namespace
    labels = merge(var.tags, { app = "jellyfin" })
  }

  spec {
    hard = {
      "pods"                   = "10"
      "requests.cpu"           = "3"
      "requests.memory"        = "4Gi"
      "limits.cpu"             = "6"
      "limits.memory"          = "8Gi"
      "persistentvolumeclaims" = "10"
    }
  }
}

resource "kubernetes_resource_quota" "pihole" {
  count = var.enable_pihole_quota ? 1 : 0

  metadata {
    name      = "pihole-quota"
    namespace = var.pihole_namespace
    labels = merge(var.tags, { app = "pihole" })
  }

  spec {
    hard = {
      "pods"            = "5"
      "requests.cpu"    = "1"
      "requests.memory" = "2Gi"
      "limits.cpu"      = "2"
      "limits.memory"   = "2Gi"
    }
  }
}

# ---- Additional namespace quotas (prevent unbounded growth) ----

resource "kubernetes_resource_quota" "argo" {
  count = var.enable_argo_quota ? 1 : 0

  metadata {
    name      = "argo-quota"
    namespace = var.argo_namespace
    labels    = var.tags
  }

  spec {
    hard = {
      "pods"            = "20"
      "requests.cpu"    = "4"
      "requests.memory" = "4Gi"
      "limits.cpu"      = "8"
      "limits.memory"   = "8Gi"
    }
  }
}

resource "kubernetes_resource_quota" "git" {
  count = var.enable_gitea_quota ? 1 : 0

  metadata {
    name      = "gitea-quota"
    namespace = var.git_namespace
    labels    = var.tags
  }

  spec {
    hard = {
      "pods"                   = "15"
      "requests.cpu"           = "3"
      "requests.memory"        = "4Gi"
      "limits.cpu"             = "6"
      "limits.memory"          = "8Gi"
      "persistentvolumeclaims" = "5"
    }
  }
}

resource "kubernetes_resource_quota" "harbor" {
  count = var.enable_harbor_quota ? 1 : 0

  metadata {
    name      = "harbor-quota"
    namespace = var.harbor_namespace
    labels    = var.tags
  }

  spec {
    hard = {
      "pods"                   = "20"
      "requests.cpu"           = "3"
      "requests.memory"        = "6Gi"
      "limits.cpu"             = "8"
      "limits.memory"          = "12Gi"
      "persistentvolumeclaims" = "10"
    }
  }
}

resource "kubernetes_resource_quota" "buildkit" {
  count = var.enable_buildkit_quota ? 1 : 0

  metadata {
    name      = "buildkit-quota"
    namespace = var.buildkit_namespace
    labels    = var.tags
  }

  spec {
    hard = {
      "pods"            = "10"
      "requests.cpu"    = "2"
      "requests.memory" = "4Gi"
      "limits.cpu"      = "6"
      "limits.memory"   = "8Gi"
    }
  }
}

resource "kubernetes_resource_quota" "awx" {
  count = var.enable_awx_quota ? 1 : 0

  metadata {
    name      = "awx-quota"
    namespace = var.awx_namespace
    labels    = var.tags
  }

  spec {
    hard = {
      "pods"                   = "20"
      "requests.cpu"           = "6"
      "requests.memory"        = "12Gi"
      "limits.cpu"             = "10"
      "limits.memory"          = "20Gi"
      "persistentvolumeclaims" = "5"
    }
  }
}

resource "kubernetes_resource_quota" "matrix" {
  count = var.enable_matrix_quota ? 1 : 0

  metadata {
    name      = "matrix-quota"
    namespace = var.matrix_namespace
    labels    = var.tags
  }

  spec {
    hard = {
      "pods"                   = "10"
      "requests.cpu"           = "2"
      "requests.memory"        = "4Gi"
      "limits.cpu"             = "4"
      "limits.memory"          = "8Gi"
      "persistentvolumeclaims" = "5"
    }
  }
}

resource "kubernetes_resource_quota" "n8n" {
  count = var.enable_n8n_quota ? 1 : 0

  metadata {
    name      = "n8n-quota"
    namespace = var.n8n_namespace
    labels    = var.tags
  }

  spec {
    hard = {
      "pods"                   = "10"
      "requests.cpu"           = "2"
      "requests.memory"        = "2Gi"
      "limits.cpu"             = "4"
      "limits.memory"          = "4Gi"
      "persistentvolumeclaims" = "5"
    }
  }
}
