#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TS="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="${ROOT_DIR}/backups/${TS}"

mkdir -p "${BACKUP_DIR}"/{terraform,pihole,cert-manager}

echo "[1/4] Backing up Terraform state"
cp "${ROOT_DIR}/terraform.tfstate" "${BACKUP_DIR}/terraform/terraform.tfstate"
cp "${ROOT_DIR}/terraform.tfstate.backup" "${BACKUP_DIR}/terraform/terraform.tfstate.backup" 2>/dev/null || true

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
EOF

ln -sfn "${BACKUP_DIR}" "${ROOT_DIR}/backups/latest"

echo "Backup complete: ${BACKUP_DIR}"
