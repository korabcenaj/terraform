output "namespace" {
  description = "Namespace where SLO PrometheusRule was created"
  value       = var.namespace
}

output "rule_name" {
  description = "PrometheusRule name"
  value       = var.rule_name
}

output "portfolio_host" {
  description = "Portfolio host targeted by SLO alerts"
  value       = var.portfolio_host
}
