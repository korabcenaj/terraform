#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CONTEXT_DIR="${REPO_ROOT}/portfolio-container"

REGISTRY_HOST="${REGISTRY_HOST:-${1:-}}"
REGISTRY_PORT="${REGISTRY_PORT:-30500}"
IMAGE_NAME="${IMAGE_NAME:-portfolio-web}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker is required to build and push the portfolio image." >&2
  exit 1
fi

if [[ -z "${REGISTRY_HOST}" ]]; then
  if ! command -v kubectl >/dev/null 2>&1; then
    echo "Pass REGISTRY_HOST or install kubectl so the script can derive a node IP." >&2
    exit 1
  fi

  REGISTRY_HOST="$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')"

  if [[ -z "${REGISTRY_HOST}" ]]; then
    echo "Failed to derive a registry host from the current cluster." >&2
    exit 1
  fi
fi

FULL_IMAGE="${REGISTRY_HOST}:${REGISTRY_PORT}/${IMAGE_NAME}:${IMAGE_TAG}"
REGISTRY_URL="http://${REGISTRY_HOST}:${REGISTRY_PORT}/v2/"

echo "Checking registry endpoint: ${REGISTRY_URL}"
curl --fail --silent --show-error "${REGISTRY_URL}" >/dev/null

echo "Building image: ${FULL_IMAGE}"
docker build -t "${FULL_IMAGE}" "${CONTEXT_DIR}"

echo "Pushing image: ${FULL_IMAGE}"
docker push "${FULL_IMAGE}"

cat <<EOF
Image pushed successfully.

Update the Argo-managed manifest in the portfolio-container repo to use:
  image: ${FULL_IMAGE}
EOF