output "namespace" {
  description = "Namespace where kube-prometheus-stack is deployed"
  value       = kubernetes_namespace.monitoring.metadata[0].name
}

output "release_name" {
  description = "Helm release name"
  value       = helm_release.kube_prometheus_stack.name
}

output "chart_version" {
  description = "Deployed kube-prometheus-stack chart version"
  value       = helm_release.kube_prometheus_stack.version
}

output "grafana_service_name" {
  description = "Service name for Grafana (referenced by monitoring ingress module)"
  value       = "${helm_release.kube_prometheus_stack.name}-grafana"
}

output "prometheus_service_name" {
  description = "Service name for Prometheus (referenced by monitoring ingress module)"
  value       = "${helm_release.kube_prometheus_stack.name}-kube-prometheus-st-prometheus"
}
