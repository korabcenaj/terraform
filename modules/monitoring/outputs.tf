output "namespace" {
  description = "Monitoring namespace"
  value       = kubernetes_namespace.monitoring.metadata[0].name
}

output "release_name" {
  description = "kube-prometheus-stack Helm release name"
  value       = helm_release.kube_prometheus_stack.name
}

output "grafana_service_name" {
  description = "Grafana service name for ingress/routing references"
  value       = "${helm_release.kube_prometheus_stack.name}-grafana"
}
