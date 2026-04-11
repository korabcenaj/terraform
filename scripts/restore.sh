#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=false
CONFIRMED=false
BACKUP_DIR_ARG=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --yes)
      CONFIRMED=true
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [--dry-run] [--yes] <backup-directory>"
      echo "Example: $0 --dry-run backups/20260411-120000"
      echo "Example: $0 --yes backups/20260411-120000"
      exit 0
      ;;
    *)
      if [[ -z "${BACKUP_DIR_ARG}" ]]; then
        BACKUP_DIR_ARG="$1"
        shift
      else
        echo "Unexpected argument: $1"
        exit 1
      fi
      ;;
  esac
done

if [[ -z "${BACKUP_DIR_ARG}" ]]; then
  echo "Usage: $0 [--dry-run] [--yes] <backup-directory>"
  echo "Example: $0 --dry-run backups/20260411-120000"
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="${ROOT_DIR}/${BACKUP_DIR_ARG}"

if [[ ! -d "${SRC_DIR}" ]]; then
  echo "Backup directory not found: ${SRC_DIR}"
  exit 1
fi

if [[ "${DRY_RUN}" == "false" && "${CONFIRMED}" == "false" ]]; then
  echo "Refusing to run destructive restore without --yes"
  echo "Use --dry-run to preview actions, or --yes to execute restore"
  exit 1
fi

echo "Restoring from: ${SRC_DIR}"

run_cmd() {
  if [[ "${DRY_RUN}" == "true" ]]; then
    echo "[DRY-RUN] $*"
  else
    eval "$*"
  fi
}

if [[ -f "${SRC_DIR}/cert-manager/local-lan-ca-secret.yaml" ]]; then
  echo "[1/3] Restoring cert-manager root CA secret"
  run_cmd "kubectl apply -f '${SRC_DIR}/cert-manager/local-lan-ca-secret.yaml'"
fi

if [[ -f "${SRC_DIR}/pihole/pihole-config.tar.gz" ]]; then
  echo "[2/3] Restoring Pi-hole configuration"
  if [[ "${DRY_RUN}" == "true" ]]; then
    echo "[DRY-RUN] kubectl get pod -n pihole -l app=pihole -o jsonpath='{.items[0].metadata.name}'"
    echo "[DRY-RUN] kubectl exec -n pihole <pod> -- sh -c 'rm -rf /etc/pihole/* /etc/dnsmasq.d/*'"
    echo "[DRY-RUN] cat '${SRC_DIR}/pihole/pihole-config.tar.gz' | kubectl exec -i -n pihole <pod> -- sh -c 'tar xzf - -C /'"
  else
    PIHOLE_POD="$(kubectl get pod -n pihole -l app=pihole -o jsonpath='{.items[0].metadata.name}')"
    kubectl exec -n pihole "${PIHOLE_POD}" -- sh -c 'rm -rf /etc/pihole/* /etc/dnsmasq.d/*'
    cat "${SRC_DIR}/pihole/pihole-config.tar.gz" | kubectl exec -i -n pihole "${PIHOLE_POD}" -- sh -c 'tar xzf - -C /'
  fi
fi

echo "[3/3] Restarting Pi-hole deployment"
run_cmd "kubectl rollout restart deployment/pihole -n pihole"
run_cmd "kubectl rollout status deployment/pihole -n pihole --timeout=120s"

echo "Restore completed."
echo "Note: Terraform state restore is manual by design."
echo "To restore state, copy backup files from ${SRC_DIR}/terraform into repo root if required."
