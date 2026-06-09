output "namespace" {
  description = "AWX namespace"
  value       = kubernetes_namespace.awx.metadata[0].name
}

output "operator_id" {
  description = "AWX Operator resource ID"
  value       = null_resource.awx_operator.id
}

output "instance_name" {
  description = "AWX instance CR name"
  value       = var.awx_instance_name
}

output "ingress_url" {
  description = "AWX web UI URL"
  value       = "https://${var.ingress_host}"
}

output "admin_user" {
  description = "AWX admin username"
  value       = var.admin_user
}
