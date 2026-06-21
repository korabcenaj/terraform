# Cilium CNI — deploys via Helm into kube-system.
# This module assumes the namespace already exists (bootstrapped by kubeadm/cluster-init).

resource "helm_release" "cilium" {
  name       = var.release_name
  repository = "https://helm.cilium.io/"
  chart      = "cilium"
  version    = var.chart_version
  namespace  = var.namespace
  timeout    = var.timeout

  # Cluster connectivity
  set {
    name  = "kubeProxyReplacement"
    value = "true"
  }

  set {
    name  = "routingMode"
    value = "native"
  }

  set {
    name  = "autoDirectNodeRoutes"
    value = "true"
  }

  set {
    name  = "ipam.mode"
    value = "kubernetes"
  }

  set {
    name  = "k8s.requireIPv4PodCIDR"
    value = "true"
  }

  set {
    name  = "endpointRoutes.enabled"
    value = "true"
  }

  # L7 proxy disabled — no Cilium L7 network policies are in use, and
  # the Envoy sidecar can intercept host-namespace port-443 traffic
  # when kube-proxy replacement is enabled, causing outbound HTTPS to
  # return Traefik's default certificate (see falco module tolerations).
  set {
    name  = "l7Proxy"
    value = "false"
  }

  # Bandwidth manager with BBR
  set {
    name  = "bandwidthManager.enabled"
    value = "true"
  }

  set {
    name  = "bandwidthManager.bbr"
    value = "true"
  }

  # BPF masquerade off (native routing)
  set {
    name  = "bpf.masquerade"
    value = "false"
  }

  # Hubble observability
  set {
    name  = "hubble.enabled"
    value = "true"
  }

  set {
    name  = "hubble.relay.enabled"
    value = "true"
  }

  set {
    name  = "hubble.ui.enabled"
    value = "true"
  }

  # Hubble metrics
  set {
    name  = "hubble.metrics.enabled"
    value = "{dns:query;ignoreAAAA,drop,tcp,flow,icmp,http,port-distribution}"
  }

  set {
    name  = "hubble.metrics.dashboards.enabled"
    value = "true"
  }

  set {
    name  = "hubble.metrics.dashboards.annotations.grafana_folder"
    value = "Cilium"
  }

  # Prometheus metrics
  set {
    name  = "prometheus.enabled"
    value = "true"
  }

  set {
    name  = "operator.prometheus.enabled"
    value = "true"
  }

  set {
    name  = "operator.dashboards.enabled"
    value = "true"
  }

  set {
    name  = "operator.dashboards.annotations.grafana_folder"
    value = "Cilium"
  }

  # Service monitors off (not using Prometheus Operator SM)
  set {
    name  = "prometheus.serviceMonitor.enabled"
    value = "false"
  }

  set {
    name  = "hubble.metrics.serviceMonitor.enabled"
    value = "false"
  }

  set {
    name  = "operator.prometheus.serviceMonitor.enabled"
    value = "false"
  }

  # Cluster identity
  set {
    name  = "cluster.name"
    value = var.cluster_name
  }

  set {
    name  = "cluster.id"
    value = var.cluster_id
  }

  # API server connectivity
  set {
    name  = "k8sServiceHost"
    value = var.k8s_api_host
  }

  set {
    name  = "k8sServicePort"
    value = var.k8s_api_port
  }

  # Node init
  set {
    name  = "nodeinit.enabled"
    value = "true"
  }

  set {
    name  = "nodeinit.bootstrapFile"
    value = "/tmp/cilium-bootstrap-time"
  }

  set {
    name  = "nodeinit.removeCbrBridge"
    value = "true"
  }

  set {
    name  = "nodeinit.removeFlannelCniConfig"
    value = "true"
  }

  # TLS
  set {
    name  = "tls.secretsBackend"
    value = "k8s"
  }

  # Security context capabilities
  set {
    name  = "securityContext.capabilities.ciliumAgent"
    value = "{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}"
  }

  set {
    name  = "securityContext.capabilities.applySysctlOverwrites"
    value = "{SYS_ADMIN,SYS_CHROOT,SYS_PTRACE,DAC_OVERRIDE}"
  }

  set {
    name  = "securityContext.capabilities.cleanCiliumState"
    value = "{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}"
  }

  # NOTE: install-cni-binaries init container capabilities are not exposed
  # by the Helm chart. A null_resource below patches the daemonset after
  # install/upgrade to add DAC_OVERRIDE so it can write to /opt/cni/bin
  # when that directory is owned by a non-root user (e.g. uid 1001).

  # Tolerations — run on all nodes including control-plane
  set {
    name  = "tolerations[0].operator"
    value = "Exists"
  }

  # Update strategy
  set {
    name  = "updateStrategy.type"
    value = "RollingUpdate"
  }

  set {
    name  = "updateStrategy.rollingUpdate.maxUnavailable"
    value = "1"
  }

  # Resources
  set {
    name  = "resources.requests.cpu"
    value = var.cpu_request
  }

  set {
    name  = "resources.requests.memory"
    value = var.memory_request
  }

  set {
    name  = "resources.limits.cpu"
    value = var.cpu_limit
  }

  set {
    name  = "resources.limits.memory"
    value = var.memory_limit
  }

  # IPv4 native routing CIDR
  set {
    name  = "ipv4NativeRoutingCIDR"
    value = var.ipv4_native_routing_cidr
  }

  # MTU
  set {
    name  = "mtu"
    value = var.mtu
  }

  # Cgroup host root
  set {
    name  = "cgroup.hostRoot"
    value = "/sys/fs/cgroup"
  }

  set {
    name  = "cgroup.autoMount.enabled"
    value = "false"
  }

  # Encryption / egress gateway off
  set {
    name  = "encryption.enabled"
    value = "false"
  }

  set {
    name  = "egressGateway.enabled"
    value = "false"
  }


  # Host firewall off — prevents cilium-agent from installing iptables
  # rules in the host namespace that can intercept outbound traffic.
  set {
    name  = "hostFirewall.enabled"
    value = "false"
  }

  # Socket LB host-namespace-only — restricts Cilium's connect()-level
  # load-balancing to pod namespaces.  Without this, host processes (e.g.,
  # falcoctl, kubelet) can have their outbound port-443 connections
  # redirected to Traefik's service backend when kube-proxy replacement
  # is active.
  set {
    name  = "socketLB.hostNamespaceOnly"
    value = "true"
  }

  # Well-known identities
  set {
    name  = "wellKnownIdentities.enabled"
    value = "true"
  }

  # Service accounts
  set {
    name  = "serviceAccounts.cilium.name"
    value = "cilium"
  }

  set {
    name  = "serviceAccounts.operator.name"
    value = "cilium-operator"
  }
}

# The install-cni-binaries init container needs DAC_OVERRIDE to write
# to /opt/cni/bin when that directory is owned by a non-root user.
# The Helm chart doesn't expose capabilities for this init container,
# so we patch the daemonset after install/upgrade.
resource "null_resource" "cilium_ds_capabilities" {
  triggers = {
    helm_release = helm_release.cilium.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      kubectl patch ds -n ${var.namespace} cilium --type=json -p='[
        {"op": "add", "path": "/spec/template/spec/initContainers/5/securityContext/capabilities/add", "value": ["NET_ADMIN","SYS_ADMIN","SYS_RESOURCE","DAC_OVERRIDE"]}
      ]' 2>/dev/null || true
    EOT
  }

  depends_on = [helm_release.cilium]
}
