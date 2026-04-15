#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

kubectl apply -f "${REPO_ROOT}/fix-registry-containerd.yaml"
kubectl -n node-maintenance rollout status daemonset/configure-local-registry --timeout=5m
kubectl -n node-maintenance get pods -o wide
kubectl -n node-maintenance logs -l app=configure-local-registry --tail=20

cat <<'EOF'

Local registry trust configuration applied to containerd nodes.

Next:
  kubectl delete pod -n portfolio -l app=portfolio
  kubectl get pods -n portfolio -w
EOF