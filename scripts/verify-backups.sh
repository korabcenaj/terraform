#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BACKUP_REF="latest"
CHECK_VELERO="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --backup-dir)
      if [[ $# -lt 2 ]]; then
        echo "--backup-dir requires a value" >&2
        exit 1
      fi
      BACKUP_REF="$2"
      shift 2
      ;;
    --check-velero)
      CHECK_VELERO="true"
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [--backup-dir <path|latest>] [--check-velero]"
      echo "Example: $0"
      echo "Example: $0 --backup-dir backups/20260415-010000"
      echo "Example: $0 --check-velero"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

resolve_backup_dir() {
  local ref="$1"
  if [[ "$ref" == "latest" ]]; then
    echo "${ROOT_DIR}/backups/latest"
  elif [[ "$ref" = /* ]]; then
    echo "$ref"
  else
    echo "${ROOT_DIR}/${ref}"
  fi
}

BACKUP_DIR="$(resolve_backup_dir "$BACKUP_REF")"
if [[ ! -e "$BACKUP_DIR" ]]; then
  echo "Backup target not found: $BACKUP_DIR" >&2
  exit 1
fi

if [[ -L "$BACKUP_DIR" ]]; then
  BACKUP_DIR="$(readlink -f "$BACKUP_DIR")"
fi

echo "Verifying backup directory: $BACKUP_DIR"

failures=0

require_path() {
  local path="$1"
  local label="$2"
  if [[ ! -e "$path" ]]; then
    echo "[FAIL] Missing $label ($path)"
    failures=$((failures + 1))
  else
    echo "[ OK ] $label"
  fi
}

require_file_nonempty() {
  local path="$1"
  local label="$2"
  if [[ ! -s "$path" ]]; then
    echo "[FAIL] Missing or empty $label ($path)"
    failures=$((failures + 1))
  else
    echo "[ OK ] $label"
  fi
}

require_path "$BACKUP_DIR" "backup directory"
require_file_nonempty "$BACKUP_DIR/metadata.txt" "metadata.txt"
require_path "$BACKUP_DIR/terraform" "terraform backup folder"

if [[ -f "$BACKUP_DIR/terraform/terraform.tfstate" || -f "$BACKUP_DIR/terraform/terraform.remote.tfstate" ]]; then
  echo "[ OK ] Terraform state snapshot (local and/or remote)"
else
  echo "[FAIL] Missing Terraform state snapshot in $BACKUP_DIR/terraform"
  failures=$((failures + 1))
fi

if [[ -f "$BACKUP_DIR/cert-manager/local-lan-ca-secret.yaml" ]]; then
  echo "[ OK ] cert-manager CA secret backup"
else
  echo "[WARN] cert-manager CA secret backup not found"
fi

if [[ -f "$BACKUP_DIR/pihole/pihole-config.tar.gz" ]]; then
  echo "[ OK ] Pi-hole config archive"
else
  echo "[WARN] Pi-hole config archive not found"
fi

if [[ "$CHECK_VELERO" == "true" ]]; then
  echo "Running Velero backup health checks"

  if ! command -v kubectl >/dev/null 2>&1; then
    echo "[FAIL] kubectl is required for --check-velero"
    failures=$((failures + 1))
  else
    if ! kubectl get namespace velero >/dev/null 2>&1; then
      echo "[FAIL] velero namespace not found"
      failures=$((failures + 1))
    else
      latest_row="$(kubectl get backups.velero.io -n velero --sort-by=.metadata.creationTimestamp -o custom-columns=NAME:.metadata.name,PHASE:.status.phase --no-headers 2>/dev/null | tail -n 1 || true)"
      if [[ -z "$latest_row" ]]; then
        echo "[FAIL] No Velero backups found"
        failures=$((failures + 1))
      else
        latest_name="$(awk '{print $1}' <<< "$latest_row")"
        latest_phase="$(awk '{print $2}' <<< "$latest_row")"
        if [[ "$latest_phase" == "Completed" ]]; then
          echo "[ OK ] Latest Velero backup completed: $latest_name"
        else
          echo "[FAIL] Latest Velero backup is not completed: $latest_name (phase=$latest_phase)"
          failures=$((failures + 1))
        fi
      fi
    fi
  fi
fi

if [[ $failures -gt 0 ]]; then
  echo "Backup verification failed with $failures issue(s)."
  exit 1
fi

echo "Backup verification passed."
