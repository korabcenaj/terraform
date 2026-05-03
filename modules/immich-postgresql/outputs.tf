output "postgresql_host" {
  value = "${helm_release.immich_postgresql.name}-postgresql.${var.namespace}.svc.cluster.local"
}

output "postgresql_port" {
  value = 5432
}

output "postgresql_user" {
  value = var.postgres_user
}

output "postgresql_password" {
  value = var.postgres_password
}

output "postgresql_db" {
  value = var.postgres_db
}
