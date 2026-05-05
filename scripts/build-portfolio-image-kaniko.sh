#!/usr/bin/env bash

set -euo pipefail

JOB_NAMESPACE="${JOB_NAMESPACE:-ci-builds}"
JOB_NAME="${JOB_NAME:-portfolio-image-build}"
GIT_CONTEXT="${GIT_CONTEXT:-git://github.com/korabcenaj/portfolio-container.git#refs/heads/main}"
DOCKERFILE_PATH="${DOCKERFILE_PATH:-Dockerfile}"
INTERNAL_DESTINATION="${INTERNAL_DESTINATION:-harbor.local.lan/library/portfolio-web:latest}"
EXTERNAL_DESTINATION="${EXTERNAL_DESTINATION:-harbor.local.lan/library/portfolio-web:latest}"
KANIKO_IMAGE="${KANIKO_IMAGE:-gcr.io/kaniko-project/executor:v1.23.2-debug}"
CA_SECRET_NAME="${CA_SECRET_NAME:-local-lan-ca}"
CA_SECRET_NAMESPACE="${CA_SECRET_NAMESPACE:-ci-builds}"

kubectl get ns "${JOB_NAMESPACE}" >/dev/null 2>&1 || kubectl create namespace "${JOB_NAMESPACE}"
kubectl -n "${JOB_NAMESPACE}" delete job "${JOB_NAME}" --ignore-not-found >/dev/null

# Ensure the local-lan-ca cert is available in ci-builds namespace so Kaniko can trust Harbor TLS
CA_PEM=$(kubectl -n cert-manager get secret local-lan-ca-secret -o jsonpath='{.data.tls\.crt}' | base64 -d)
kubectl -n "${JOB_NAMESPACE}" create secret generic "${CA_SECRET_NAME}" \
  --from-literal=ca.crt="${CA_PEM}" \
  --dry-run=client -o yaml | kubectl apply -f -

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
      volumes:
      - name: local-lan-ca
        secret:
          secretName: ${CA_SECRET_NAME}
      containers:
      - name: kaniko
        image: ${KANIKO_IMAGE}
        args:
        - --context=${GIT_CONTEXT}
        - --dockerfile=${DOCKERFILE_PATH}
        - --destination=${INTERNAL_DESTINATION}
        - --cache=false
        volumeMounts:
        - name: local-lan-ca
          mountPath: /kaniko/ssl/certs/local-lan-ca.crt
          subPath: ca.crt
          readOnly: true
EOF

kubectl -n "${JOB_NAMESPACE}" wait --for=condition=complete --timeout=10m "job/${JOB_NAME}"
kubectl -n "${JOB_NAMESPACE}" logs "job/${JOB_NAME}"

cat <<EOF

Kaniko push finished.

The image is now available from the registry pod and should be referenced by workloads as:
  ${EXTERNAL_DESTINATION}

If the Argo-managed manifest still points elsewhere, update it before syncing.
EOF