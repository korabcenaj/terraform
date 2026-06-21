# AI and GPU Audit Report

Generated: 20260414-195739
Kubernetes context: kubernetes-admin@kubernetes

## Cluster Snapshot
- Nodes discovered: 4
- Nodes with GPU allocatable: k8s3
- AI-like namespaces detected: ai-orchestrator
- AI-like workload candidates (name/image match): 27
- Pods with explicit GPU request/limit: 0

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
