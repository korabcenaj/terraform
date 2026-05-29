output "namespace" {
  description = "Traefik namespace"
  value       = kubernetes_namespace.traefik.metadata[0].name
}

output "release_name" {
  description = "Helm release name"
  value       = helm_release.traefik.name
}
