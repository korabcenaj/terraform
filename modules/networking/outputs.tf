output "network_policies_created" {
  value = length(var.namespaces_with_policies)
}
