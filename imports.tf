################################################################################
# Terraform Import Blocks (Terraform 1.5+)
#
# These blocks import pre-existing cluster resources into Terraform state so
# they can be managed going forward without recreation.
#
# USAGE:
#   1. Ensure the target module/resource is enabled in terraform.tfvars
#      (enable_cert_manager = true, manage_cert_manager_controller = true,
#       enable_ai_orchestrator = true)
#   2. If cert-manager was installed via plain kubectl (no Helm release secret),
#      first adopt it into Helm:
#        helm -n cert-manager upgrade --install cert-manager \
#          jetstack/cert-manager --version v1.17.1 \
#          --reuse-values
#      This creates the Helm release secret so the import below can succeed.
#   3. Run: terraform plan   (Terraform will show import + no-change plan)
#   4. Run: terraform apply
#   5. These blocks are safe to leave in permanently. Terraform is idempotent:
#      if a resource is already in state the import is a no-op.
################################################################################

# ---------------------------------------------------------------------------
# cert-manager — adopted from manual/pre-Terraform installation
# ---------------------------------------------------------------------------

import {
  to = module.cert_manager[0].kubernetes_namespace.cert_manager
  id = "cert-manager"
}

import {
  to = module.cert_manager[0].helm_release.cert_manager[0]
  id = "cert-manager/cert-manager"
}

# ---------------------------------------------------------------------------
# Existing cluster resources to adopt into Terraform state
# ---------------------------------------------------------------------------

import {
  to = kubernetes_service_account_v1.kaniko_builder
  id = "default/kaniko-builder"
}

import {
  to = module.ai_orchestrator[0].kubernetes_network_policy_v1.default_deny_ingress
  id = "ai-orchestrator/default-deny-ingress"
}

import {
  to = module.ai_orchestrator[0].kubernetes_network_policy_v1.allow_dns_egress
  id = "ai-orchestrator/allow-dns-egress"
}

import {
  to = module.skills_dashboard[0].kubernetes_namespace_v1.dashboard
  id = "default"
}

import {
  to = module.skills_dashboard[0].kubernetes_service_account_v1.dashboard
  id = "default/skills-dashboard"
}

import {
  to = module.skills_dashboard[0].kubernetes_cluster_role_v1.dashboard
  id = "skills-dashboard"
}

import {
  to = module.skills_dashboard[0].kubernetes_cluster_role_binding_v1.dashboard
  id = "skills-dashboard"
}

import {
  to = module.skills_dashboard[0].kubernetes_deployment_v1.dashboard
  id = "default/skills-dashboard"
}

import {
  to = module.skills_dashboard[0].kubernetes_service_v1.dashboard
  id = "default/skills-dashboard"
}

import {
  to = module.skills_dashboard[0].kubernetes_ingress_v1.dashboard[0]
  id = "default/skills-dashboard"
}

import {
  to = kubernetes_namespace.ci_builds
  id = "ci-builds"
}


