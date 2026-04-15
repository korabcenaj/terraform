#!/usr/bin/env bash

set -euo pipefail

JOB_NAMESPACE="${JOB_NAMESPACE:-ci-builds}"
JOB_NAME="${JOB_NAME:-portfolio-image-build}"
GIT_CONTEXT="${GIT_CONTEXT:-git://github.com/korabcenaj/portfolio-container.git#refs/heads/main}"
DOCKERFILE_PATH="${DOCKERFILE_PATH:-Dockerfile}"
INTERNAL_DESTINATION="${INTERNAL_DESTINATION:-registry.registry.svc.cluster.local:5000/portfolio-web:latest}"
EXTERNAL_DESTINATION="${EXTERNAL_DESTINATION:-192.168.1.10:30500/portfolio-web:latest}"
KANIKO_IMAGE="${KANIKO_IMAGE:-gcr.io/kaniko-project/executor:v1.23.2-debug}"

kubectl get ns "${JOB_NAMESPACE}" >/dev/null 2>&1 || kubectl create namespace "${JOB_NAMESPACE}"

kubectl -n "${JOB_NAMESPACE}" delete job "${JOB_NAME}" --ignore-not-found >/dev/null

cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: ${JOB_NAME}
  namespace: ${JOB_NAMESPACE}
spec:
  backoffLimit: 0
  ttlSecondsAfterFinished: 3600
  template:
    metadata:
      labels:
        app: ${JOB_NAME}
    spec:
      restartPolicy: Never
      containers:
      - name: kaniko
        image: ${KANIKO_IMAGE}
        args:
        - --context=${GIT_CONTEXT}
        - --dockerfile=${DOCKERFILE_PATH}
        - --destination=${INTERNAL_DESTINATION}
        - --insecure
        - --skip-tls-verify
        - --cache=false
EOF

kubectl -n "${JOB_NAMESPACE}" wait --for=condition=complete --timeout=10m "job/${JOB_NAME}"
kubectl -n "${JOB_NAMESPACE}" logs "job/${JOB_NAME}"

cat <<EOF

Kaniko push finished.

The image is now available from the registry pod and should be referenced by workloads as:
  ${EXTERNAL_DESTINATION}

If the Argo-managed manifest still points elsewhere, update it before syncing.
EOF