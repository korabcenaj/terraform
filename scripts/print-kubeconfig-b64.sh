#!/usr/bin/env bash
set -euo pipefail

KUBECONFIG_PATH="${1:-${KUBECONFIG:-$HOME/.kube/config}}"

if [[ ! -f "${KUBECONFIG_PATH}" ]]; then
  echo "Kubeconfig not found: ${KUBECONFIG_PATH}"
  exit 1
fi

base64 < "${KUBECONFIG_PATH}" | tr -d '\n'
echo