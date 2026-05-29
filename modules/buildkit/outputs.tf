output "namespace" {
  description = "BuildKit namespace"
  value       = kubernetes_namespace.buildkit.metadata[0].name
}
