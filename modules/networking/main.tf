# CoreDNS — add stub zone for private domain so in-cluster pods resolve *.local.lan
resource "kubernetes_config_map_v1" "coredns" {
  count = var.coredns_local_dns_ip != "" ? 1 : 0

  metadata {
    name      = "coredns"
    namespace = "kube-system"
  }

  data = {
    Corefile = <<-COREFILE
      .:53 {
          errors
          health {
             lameduck 5s
          }
          ready
          kubernetes cluster.local in-addr.arpa ip6.arpa {
             pods insecure
             fallthrough in-addr.arpa ip6.arpa
             ttl 30
          }
          prometheus :9153
          forward . 8.8.8.8 1.1.1.1 {
             max_concurrent 1000
          }
          cache 30
          loop
          reload
          loadbalance
      }
      ${var.coredns_local_domain}:53 {
          errors
          cache 30
          forward . ${var.coredns_local_dns_ip}
      }
    COREFILE
  }

  lifecycle {
    prevent_destroy = true
    # Avoid conflicts with kubeadm / kube-system default management
    ignore_changes = [metadata[0].annotations, metadata[0].labels]
  }
}

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

      ports {
        port     = "53"
        protocol = "TCP"
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
