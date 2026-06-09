output "namespace" {
  description = "Rancher namespace"
  value       = kubernetes_namespace.cattle_system.metadata[0].name
}
