#!/usr/bin/env bash
set -euo pipefail

if command -v gh >/dev/null 2>&1; then
  echo "gh is already installed: $(command -v gh)"
  gh --version | head -n 1
  exit 0
fi

if [[ "$(id -u)" -eq 0 ]]; then
  SUDO=""
elif command -v sudo >/dev/null 2>&1; then
  SUDO="sudo"
else
  echo "Root or sudo is required to install gh."
  exit 1
fi

if [[ -n "${SUDO}" ]] && [[ ! -t 0 ]] && ! sudo -n true >/dev/null 2>&1; then
  echo "sudo requires a password and this shell is non-interactive."
  echo "Run ./scripts/install-gh.sh directly in an interactive terminal and enter your sudo password when prompted."
  exit 1
fi

. /etc/os-release

case "${ID:-}" in
  ubuntu|debian)
    ${SUDO} apt-get update
    ${SUDO} apt-get install -y curl gpg
    ${SUDO} mkdir -p /etc/apt/keyrings
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | ${SUDO} dd of=/etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
    ${SUDO} chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | ${SUDO} tee /etc/apt/sources.list.d/github-cli.list >/dev/null
    ${SUDO} apt-get update
    ${SUDO} apt-get install -y gh
    ;;
  *)
    echo "Unsupported distribution: ${ID:-unknown}"
    echo "Install gh manually from https://cli.github.com/ and re-run the secret helper."
    exit 1
    ;;
esac

gh --version | head -n 1