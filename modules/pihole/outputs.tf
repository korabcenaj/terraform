output "namespace" {
  description = "Pi-hole namespace"
  value       = var.namespace
}

output "service_name" {
  description = "Pi-hole service name"
  value       = kubernetes_service.pihole.metadata[0].name
}

output "service_ip" {
  description = "Pi-hole external LoadBalancer IP"
  value       = try(kubernetes_service.pihole.status[0].load_balancer[0].ingress[0].ip, null)
}

output "dns_server" {
  description = "DNS server address (use this to configure your router)"
  value       = try(kubernetes_service.pihole.status[0].load_balancer[0].ingress[0].ip, "pending")
}

output "web_ui_url" {
  description = "Pi-hole web UI URL"
  value       = "http://${var.ingress_host}/admin"
}

output "ingress_host" {
  description = "Pi-hole ingress hostname"
  value       = try(kubernetes_ingress_v1.pihole.spec[0].rule[0].host, null)
}
