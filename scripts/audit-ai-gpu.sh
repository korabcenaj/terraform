#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TS="$(date +%Y%m%d-%H%M%S)"
REPORT_DIR="${ROOT_DIR}/reports/ai-gpu-audit-${TS}"
AI_REGEX='ai|ml|llm|model|inference|ollama|vllm|huggingface|openwebui|stable-diffusion|comfy|langchain|vector|embedding|vision|whisper|rerank|gpu'

mkdir -p "${REPORT_DIR}"

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command: $cmd" >&2
    exit 1
  fi
}

require_cmd kubectl
require_cmd awk
require_cmd grep
require_cmd sort
require_cmd uniq

if ! kubectl config current-context >/dev/null 2>&1; then
  echo "kubectl has no active context. Configure kubeconfig first." >&2
  exit 1
fi

KCTX="$(kubectl config current-context)"

echo "[1/8] Collecting node inventory"
kubectl get nodes -o wide > "${REPORT_DIR}/nodes-wide.txt"
kubectl get nodes -o custom-columns=NAME:.metadata.name,ROLES:.metadata.labels.kubernetes\\.io/role,GPU_ALLOCATABLE:.status.allocatable.nvidia\\.com/gpu --no-headers \
  > "${REPORT_DIR}/nodes-gpu.txt"

echo "[2/8] Collecting NVIDIA components"
kubectl get daemonset --all-namespaces --no-headers | grep -i nvidia > "${REPORT_DIR}/nvidia-daemonsets.txt" || true

echo "[3/8] Collecting all running pods"
kubectl get pods --all-namespaces -o wide --no-headers > "${REPORT_DIR}/pods-wide.txt"

echo "[4/8] Collecting pod images"
kubectl get pods --all-namespaces -o custom-columns=NAMESPACE:.metadata.namespace,POD:.metadata.name,NODE:.spec.nodeName,IMAGES:.spec.containers[*].image --no-headers \
  > "${REPORT_DIR}/pod-images.txt"

echo "[5/8] Detecting AI candidates"
grep -Ei "${AI_REGEX}" "${REPORT_DIR}/pod-images.txt" > "${REPORT_DIR}/ai-candidates-by-image.txt" || true
grep -Ei "${AI_REGEX}" "${REPORT_DIR}/pods-wide.txt" > "${REPORT_DIR}/ai-candidates-by-name.txt" || true

echo "[6/8] Detecting GPU resource requests"
kubectl get pods --all-namespaces \
  -o jsonpath='{range .items[*]}{.metadata.namespace}{"\t"}{.metadata.name}{"\t"}{.spec.nodeName}{"\t"}{range .spec.containers[*]}{.name}{":"}{.resources.limits.nvidia\.com/gpu}{"/"}{.resources.requests.nvidia\.com/gpu}{","}{end}{"\n"}{end}' \
  > "${REPORT_DIR}/pods-gpu-resources-raw.txt"
awk -F '\t' '$4 ~ /[1-9]/ {print $0}' "${REPORT_DIR}/pods-gpu-resources-raw.txt" > "${REPORT_DIR}/pods-gpu-requests.txt" || true

echo "[7/8] Capturing utilization snapshot"
kubectl top nodes > "${REPORT_DIR}/top-nodes.txt" 2> "${REPORT_DIR}/top-nodes.err" || true
kubectl top pods --all-namespaces > "${REPORT_DIR}/top-pods.txt" 2> "${REPORT_DIR}/top-pods.err" || true

echo "[8/8] Writing summary"
NODE_COUNT="$(wc -l < "${REPORT_DIR}/nodes-gpu.txt" | tr -d ' ')"
GPU_NODES="$(awk '{if ($3 != "<none>" && $3 != "") print $1}' "${REPORT_DIR}/nodes-gpu.txt" | sort -u | tr '\n' ',' | sed 's/,$//')"
if [[ -z "${GPU_NODES}" ]]; then
  GPU_NODES="none"
fi

AI_CANDIDATE_COUNT="$(cat "${REPORT_DIR}/ai-candidates-by-image.txt" "${REPORT_DIR}/ai-candidates-by-name.txt" 2>/dev/null | awk 'NF' | sort -u | wc -l | tr -d ' ')"
GPU_POD_COUNT="$(awk 'NF' "${REPORT_DIR}/pods-gpu-requests.txt" 2>/dev/null | wc -l | tr -d ' ')"
AI_NAMESPACES="$(awk '{print $1}' "${REPORT_DIR}/pods-wide.txt" | grep -Ei "${AI_REGEX}" | sort -u | tr '\n' ',' | sed 's/,$//')"
if [[ -z "${AI_NAMESPACES}" ]]; then
  AI_NAMESPACES="none"
fi

cat > "${REPORT_DIR}/summary.md" <<EOF
# AI and GPU Audit Report

Generated: ${TS}
Kubernetes context: ${KCTX}

## Cluster Snapshot
- Nodes discovered: ${NODE_COUNT}
- Nodes with GPU allocatable: ${GPU_NODES}
- AI-like namespaces detected: ${AI_NAMESPACES}
- AI-like workload candidates (name/image match): ${AI_CANDIDATE_COUNT}
- Pods with explicit GPU request/limit: ${GPU_POD_COUNT}

## Files
- nodes inventory: nodes-wide.txt
- GPU allocatable by node: nodes-gpu.txt
- NVIDIA daemonsets: nvidia-daemonsets.txt
- all pods: pods-wide.txt
- pod images: pod-images.txt
- AI candidates by image: ai-candidates-by-image.txt
- AI candidates by name: ai-candidates-by-name.txt
- raw GPU resources: pods-gpu-resources-raw.txt
- pods requesting GPUs: pods-gpu-requests.txt
- utilization: top-nodes.txt and top-pods.txt

## Terraform Adoption Next Step
Use this report to map each AI candidate into one of three categories:
1. Terraform-managed already
2. Running but not Terraform-managed
3. Missing from cluster but declared in Terraform

For category 2 workloads, create module boundaries and import/apply strategy before enabling management from root main.tf.
EOF

echo "Audit complete: ${REPORT_DIR}"
