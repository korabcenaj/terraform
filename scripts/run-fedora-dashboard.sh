#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PYTHON_BIN="${PYTHON_BIN:-python3}"

# Prefer ~/.local/bin so user-installed terraform/kubectl are found first.
export PATH="${HOME}/.local/bin:${PATH}"

if ! command -v "${PYTHON_BIN}" >/dev/null 2>&1; then
  echo "python3 is required. Install with: sudo dnf install -y python3"
  exit 1
fi

"${PYTHON_BIN}" "${REPO_ROOT}/dashboard/generate_dashboard.py"

if command -v xdg-open >/dev/null 2>&1; then
  xdg-open "${REPO_ROOT}/dashboard/index.html" >/dev/null 2>&1 || true
fi

echo "Open in browser: ${REPO_ROOT}/dashboard/index.html"
