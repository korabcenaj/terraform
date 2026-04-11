output "namespace" {
  description = "Namespace where metrics-server is deployed"
  value       = var.namespace
}

output "release_name" {
  description = "Metrics-server deployment name"
  value       = kubernetes_deployment_v1.metrics_server.metadata[0].name
}
