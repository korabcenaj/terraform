output "namespace" {
  value = var.namespace
}

output "deployment_name" {
  value = kubernetes_deployment.portfolio.metadata[0].name
}

output "service_name" {
  value = kubernetes_service.portfolio.metadata[0].name
}

output "service_endpoint" {
  value = "${kubernetes_service.portfolio.metadata[0].name}.${var.namespace}.svc.cluster.local"
}

output "configmap_name" {
  value = kubernetes_config_map.portfolio_static.metadata[0].name
}
