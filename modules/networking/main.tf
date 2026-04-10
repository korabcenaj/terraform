# Default deny all ingress traffic for each namespace
resource "kubernetes_network_policy" "default_deny_ingress" {
  for_each = toset(var.namespaces_with_policies)

  metadata {
    name      = "default-deny-ingress"
    namespace = each.value
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress"]
  }
}

# Allow DNS for all pods
resource "kubernetes_network_policy" "allow_dns" {
  for_each = toset(var.namespaces_with_policies)

  metadata {
    name      = "allow-dns-egress"
    namespace = each.value
  }

  spec {
    pod_selector {}
    policy_types = ["Egress"]

    egress {
      ports {
        port     = "53"
        protocol = "UDP"
      }

      to {
        namespace_selector {
          match_labels = {
            name = "kube-system"
          }
        }
      }
    }
  }
}

# Allow nginx-ingress to reach pods in default namespace
resource "kubernetes_network_policy" "allow_from_ingress" {
  #for_each = toset(var.namespaces_with_policies)
  for_each = toset([for ns in var.namespaces_with_policies : ns if ns == "default"])
#  count     = each.value == "default" ? 1 : 0
  metadata {
    name      = "allow-from-ingress"
    namespace = each.value
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress"]

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = "ingress-nginx"
          }
        }
      }

      ports {
        port     = "80"
        protocol = "TCP"
      }

      ports {
        port     = "443"
        protocol = "TCP"
      }
    }
  }
}
