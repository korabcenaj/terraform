output "namespace" {
  description = "Namespace where AI orchestrator workloads run"
  value       = kubernetes_namespace.ai_orchestrator.metadata[0].name
}
