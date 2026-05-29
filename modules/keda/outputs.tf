output "namespace" {
  description = "KEDA namespace"
  value       = kubernetes_namespace.keda.metadata[0].name
}

output "release_name" {
  description = "Helm release name"
  value       = helm_release.keda.name
}
