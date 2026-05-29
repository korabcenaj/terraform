output "namespace" {
  description = "Grafana Alloy namespace"
  value       = kubernetes_namespace.grafana_alloy.metadata[0].name
}

output "release_name" {
  description = "Helm release name"
  value       = helm_release.grafana_k8s_monitoring.name
}
