output "namespace" {
  description = "Namespace where MinIO is deployed"
  value       = kubernetes_namespace.minio.metadata[0].name
}

output "release_name" {
  description = "Helm release name"
  value       = helm_release.minio.name
}

output "chart_version" {
  description = "Deployed MinIO chart version"
  value       = helm_release.minio.version
}

output "service_name" {
  description = "MinIO service name"
  value       = helm_release.minio.name
}

output "ingress_host" {
  description = "MinIO console ingress hostname"
  value       = var.ingress_host
}