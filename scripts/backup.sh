#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TS="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="${ROOT_DIR}/backups/${TS}"

mkdir -p "${BACKUP_DIR}"/{terraform,pihole,cert-manager}

echo "[1/4] Backing up Terraform state"
STATE_SOURCE="none"
LOCAL_STATE_COPIED="false"

if [[ -f "${ROOT_DIR}/terraform.tfstate" ]]; then
  cp "${ROOT_DIR}/terraform.tfstate" "${BACKUP_DIR}/terraform/terraform.tfstate"
  cp "${ROOT_DIR}/terraform.tfstate.backup" "${BACKUP_DIR}/terraform/terraform.tfstate.backup" 2>/dev/null || true
  STATE_SOURCE="local"
  LOCAL_STATE_COPIED="true"
fi

REMOTE_STATE_FILE="${BACKUP_DIR}/terraform/terraform.remote.tfstate"
if command -v terraform >/dev/null 2>&1; then
  if terraform -chdir="${ROOT_DIR}" state pull > "${REMOTE_STATE_FILE}" 2>/dev/null; then
    if [[ -s "${REMOTE_STATE_FILE}" ]]; then
      STATE_SOURCE="${STATE_SOURCE/local/local+remote}"
      [[ "${LOCAL_STATE_COPIED}" == "false" ]] && STATE_SOURCE="remote"
    else
      rm -f "${REMOTE_STATE_FILE}"
    fi
  else
    rm -f "${REMOTE_STATE_FILE}"
  fi
fi

if [[ "${STATE_SOURCE}" == "none" ]]; then
  echo "Warning: no Terraform state was backed up (no local state file and state pull failed)."
fi

if [[ -f "${ROOT_DIR}/.terraform.lock.hcl" ]]; then
  cp "${ROOT_DIR}/.terraform.lock.hcl" "${BACKUP_DIR}/terraform/.terraform.lock.hcl"
fi

echo "[2/4] Backing up cert-manager root CA secret"
kubectl get secret -n cert-manager local-lan-ca-secret -o yaml > "${BACKUP_DIR}/cert-manager/local-lan-ca-secret.yaml"

echo "[3/4] Backing up Pi-hole configuration"
PIHOLE_POD="$(kubectl get pod -n pihole -l app=pihole -o jsonpath='{.items[0].metadata.name}')"
kubectl exec -n pihole "${PIHOLE_POD}" -- sh -c 'tar czf - /etc/pihole /etc/dnsmasq.d' > "${BACKUP_DIR}/pihole/pihole-config.tar.gz"

echo "[4/4] Writing metadata"
cat > "${BACKUP_DIR}/metadata.txt" <<EOF
backup_timestamp=${TS}
k8s_context=$(kubectl config current-context)
cluster_nodes=$(kubectl get nodes --no-headers | wc -l | tr -d ' ')
terraform_state_source=${STATE_SOURCE}
terraform_version=$(terraform version -json 2>/dev/null | grep -oE '"terraform_version":"[^"]+"' | cut -d '"' -f4 || echo "unknown")
EOF

ln -sfn "${BACKUP_DIR}" "${ROOT_DIR}/backups/latest"

echo "Backup complete: ${BACKUP_DIR}"
