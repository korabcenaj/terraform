output "namespace" {
  description = "Rancher namespace"
  value       = kubernetes_namespace.cattle_system.metadata[0].name
}

output "release_name" {
  description = "Helm release name"
  value       = helm_release.rancher.name
}

output "hostname" {
  description = "Rancher server hostname"
  value       = var.hostname
}
