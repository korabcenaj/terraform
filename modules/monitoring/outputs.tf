output "monitoring_namespace" {
  value = data.kubernetes_namespace.monitoring.metadata[0].name
}
