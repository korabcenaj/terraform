output "release_name" {
  description = "Longhorn Helm release name"
  value       = helm_release.longhorn.name
}

output "namespace" {
  description = "Longhorn namespace"
  value       = kubernetes_namespace.longhorn.metadata[0].name
}
