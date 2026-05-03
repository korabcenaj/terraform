resource "helm_release" "immich_postgresql" {
  name       = "immich-postgresql"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "postgresql"
  version    = "15.2.5"

  namespace  = var.namespace

  values = [
    yamlencode({
      global: {
        postgresql: {
          auth: {
            postgresPassword: var.postgres_password
            username: var.postgres_user
            password: var.postgres_password
            database: var.postgres_db
          }
        }
      }
      primary: {
        persistence: {
          enabled: true
          size: "8Gi"
        }
      }
    })
  ]
}
