#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${GH_REPO_URL:-https://github.com/korabcenaj/terraform}"
RUNNER_DIR="${HOME}/actions-runner"
RUNNER_NAME="$(hostname)-terraform"
RUNNER_LABELS="homelab,terraform"
RUNNER_TOKEN="${GH_RUNNER_TOKEN:-}"
INSTALL_SERVICE=false
ACTION="install"

has_runner_service() {
  [[ -x ./svc.sh ]] && command -v sudo >/dev/null 2>&1
}

runner_configured() {
  [[ -f .runner ]]
}

start_runner() {
  if has_runner_service; then
    sudo ./svc.sh start
    echo "Runner service started."
  else
    echo "Service management is unavailable. Start the runner manually with: ${RUNNER_DIR}/run.sh"
    exit 1
  fi
}

stop_runner() {
  if has_runner_service; then
    sudo ./svc.sh stop
    echo "Runner service stopped."
  else
    echo "Service management is unavailable. Stop the runner manually if it is running in a shell."
    exit 1
  fi
}

remove_runner() {
  if ! runner_configured; then
    echo "Runner is not configured in ${RUNNER_DIR}."
    return 0
  fi

  if has_runner_service; then
    sudo ./svc.sh stop || true
    sudo ./svc.sh uninstall || true
  fi

  if [[ -z "${RUNNER_TOKEN}" ]]; then
    echo "Runner removal requires a fresh registration/removal token. Pass --token or set GH_RUNNER_TOKEN."
    exit 1
  fi

  ./config.sh remove --token "${RUNNER_TOKEN}"
  echo "Runner removed from ${REPO_URL}."
}

print_status() {
  echo "Repository URL: ${REPO_URL}"
  echo "Runner directory: ${RUNNER_DIR}"
  echo "Runner configured: $(runner_configured && echo yes || echo no)"
  echo "Service management available: $(has_runner_service && echo yes || echo no)"
}

usage() {
  echo "Usage: $0 [install|start|stop|status|remove] [--token <runner-token>] [--dir <runner-dir>] [--name <runner-name>] [--labels <comma-separated-labels>] [--service]"
  echo "Examples:"
  echo "  $0 install --token <runner-registration-token> --service"
  echo "  $0 status"
  echo "  $0 remove --token <runner-removal-token>"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    install|start|stop|status|remove)
      ACTION="$1"
      shift
      ;;
    --token)
      RUNNER_TOKEN="$2"
      shift 2
      ;;
    --dir)
      RUNNER_DIR="$2"
      shift 2
      ;;
    --name)
      RUNNER_NAME="$2"
      shift 2
      ;;
    --labels)
      RUNNER_LABELS="$2"
      shift 2
      ;;
    --service)
      INSTALL_SERVICE=true
      shift
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

for cmd in curl tar; do
  if [[ "${ACTION}" == "install" ]] && ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "Missing required command: ${cmd}"
    exit 1
  fi
done

mkdir -p "${RUNNER_DIR}"
cd "${RUNNER_DIR}"

case "${ACTION}" in
  status)
    print_status
    exit 0
    ;;
  start)
    start_runner
    exit 0
    ;;
  stop)
    stop_runner
    exit 0
    ;;
  remove)
    remove_runner
    exit 0
    ;;
esac

if [[ -z "${RUNNER_TOKEN}" ]]; then
  echo "Runner registration token is required. Pass --token or set GH_RUNNER_TOKEN."
  exit 1
fi

if [[ ! -x ./config.sh ]]; then
  archive="actions-runner-linux-x64.tar.gz"
  curl -fsSL -o "${archive}" "https://github.com/actions/runner/releases/latest/download/actions-runner-linux-x64.tar.gz"
  tar xzf "${archive}"
  rm -f "${archive}"
fi

if [[ -f .runner ]]; then
  echo "Runner already configured in ${RUNNER_DIR}."
else
  ./config.sh \
    --url "${REPO_URL}" \
    --token "${RUNNER_TOKEN}" \
    --name "${RUNNER_NAME}" \
    --labels "${RUNNER_LABELS}" \
    --unattended \
    --replace
fi

if [[ "${INSTALL_SERVICE}" == "true" ]]; then
  if [[ -x ./svc.sh ]] && command -v sudo >/dev/null 2>&1; then
    sudo ./svc.sh install
    sudo ./svc.sh start
    echo "Runner service installed and started."
  else
    echo "Service install requested, but svc.sh or sudo is unavailable."
    echo "Start the runner manually with: ${RUNNER_DIR}/run.sh"
    exit 1
  fi
else
  echo "Runner configured. Start it with: ${RUNNER_DIR}/run.sh"
fi