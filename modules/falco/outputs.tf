output "namespace" {
  description = "Falco namespace"
  value       = kubernetes_namespace.falco.metadata[0].name
}

output "release_name" {
  description = "Helm release name"
  value       = helm_release.falco.name
}
