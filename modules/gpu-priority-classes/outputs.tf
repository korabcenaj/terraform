output "interactive_priority_class" {
  description = "Interactive GPU PriorityClass name"
  value       = kubernetes_priority_class_v1.gpu_interactive.metadata[0].name
}

output "batch_priority_class" {
  description = "Batch GPU PriorityClass name"
  value       = kubernetes_priority_class_v1.gpu_batch.metadata[0].name
}
