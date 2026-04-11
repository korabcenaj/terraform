#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_URL="${GH_REPO_URL:-https://github.com/korabcenaj/terraform}"
SECRET_NAME="KUBECONFIG_B64"
KUBECONFIG_PATH="${KUBECONFIG:-$HOME/.kube/config}"

usage() {
  echo "Usage: $0 [--name <secret-name>] [--kubeconfig <path>] [--repo <owner/repo|url>]"
  echo "Example: $0 --name KUBECONFIG_B64 --kubeconfig ~/.kube/config"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name)
      SECRET_NAME="$2"
      shift 2
      ;;
    --kubeconfig)
      KUBECONFIG_PATH="$2"
      shift 2
      ;;
    --repo)
      REPO_URL="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unexpected argument: $1"
      usage
      exit 1
      ;;
  esac
done

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI (gh) is required. Install it first and authenticate with: gh auth login"
  exit 1
fi

if [[ ! -f "${KUBECONFIG_PATH}" ]]; then
  echo "Kubeconfig not found: ${KUBECONFIG_PATH}"
  exit 1
fi

gh auth status >/dev/null 2>&1 || {
  echo "GitHub CLI is not authenticated. Run: gh auth login"
  exit 1
}

REPO_ARG="${REPO_URL}"
if [[ "${REPO_ARG}" =~ ^https://github.com/ ]]; then
  REPO_ARG="${REPO_ARG#https://github.com/}"
fi
REPO_ARG="${REPO_ARG%.git}"

"${SCRIPT_DIR}/print-kubeconfig-b64.sh" "${KUBECONFIG_PATH}" | gh secret set "${SECRET_NAME}" --repo "${REPO_ARG}"

echo "Secret ${SECRET_NAME} updated for ${REPO_ARG}."