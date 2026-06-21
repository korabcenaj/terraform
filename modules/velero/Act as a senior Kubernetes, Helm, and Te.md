Act as a senior Kubernetes, Helm, and Terraform engineer.

I am recovering a Terraform-managed Kubernetes homelab that is currently in a partially failed state.

Your task is to analyze the provided errors and outputs, identify the root causes, and give exact commands and code changes required to restore the environment to a healthy, Terraform-managed state.

Do not provide multiple options unless absolutely necessary. Make a recommendation and explain why it is the safest approach.

Assume:

Terraform is the source of truth.
Existing cluster resources should be preserved whenever possible.
Downtime should be minimized.
Any resource that already exists in Kubernetes but not in Terraform state should be imported rather than recreated unless there is a compelling reason not to.
Helm releases stuck in pending-upgrade should be investigated and remediated.
Velero configuration must be corrected to match the current chart schema.

For each issue:

Identify the root cause.
Specify the exact commands to run.
Specify any Terraform code changes required.
Explain the expected outcome.
Continue to the next issue until the environment is fully recoverable.

At the end, provide the exact verification commands that should show a healthy cluster and a successful terraform plan.

Here are the errors and command outputs:

helm list -A

helm status cilium -n kube-system
helm status kube-prometheus-stack -n monitoring
helm status oauth2-proxy -n oauth2-proxy
NAME NAMESPACE REVISION UPDATED STATUS CHART APP VERSION
cert-manager cert-manager 1 2026-06-15 13:19:25.120839395 +0200 CEST deployed cert-manager-v1.14.5 v1.14.5
cilium kube-system 3 2026-06-19 17:02:36.914251105 +0200 CEST pending-upgrade cilium-1.19.4 1.19.4
falco falco 2 2026-06-19 17:02:42.317152136 +0200 CEST deployed falco-8.0.2 0.43.1
gitea git 4 2026-06-17 11:21:24.104564781 +0200 CEST deployed gitea-12.5.3 1.25.5
harbor harbor 1 2026-06-15 13:30:05.036609973 +0200 CEST deployed harbor-1.19.0 2.15.0
keda keda 1 2026-06-15 13:19:18.078107917 +0200 CEST deployed keda-2.19.0 2.19.0
kps monitoring 2 2026-06-19 17:02:50.202698091 +0200 CEST pending-upgrade kube-prometheus-stack-86.2.3 v0.91.0
loki logging 15 2026-06-19 18:10:24.994876805 +0200 CEST deployed loki-stack-2.10.3 v2.9.3
longhorn longhorn-system 2 2026-06-19 17:02:50.605233402 +0200 CEST deployed longhorn-1.12.0 v1.12.0
metallb metallb-system 2 2026-06-19 17:02:47.140418823 +0200 CEST deployed metallb-0.15.3 v0.15.3
oauth2-proxy oauth2-proxy 2 2026-06-19 17:15:08.258989804 +0200 CEST pending-upgrade oauth2-proxy-7.7.1 7.6.0
tempo tracing 4 2026-06-19 18:15:19.166231964 +0200 CEST deployed tempo-1.24.4 2.9.0
traefik traefik 2 2026-06-19 17:15:02.875648917 +0200 CEST deployed traefik-40.2.0 v3.7.1
velero velero 8 2026-06-19 17:22:32.159565915 +0200 CEST failed velero-12.0.3 1.18.1
NAME: cilium
LAST DEPLOYED: Fri Jun 19 17:02:36 2026
NAMESPACE: kube-system
STATUS: pending-upgrade
REVISION: 3
DESCRIPTION: Preparing upgrade
RESOURCES:
==> v1/Namespace
NAME STATUS AGE
cilium-secrets Active 3d1h

==> v1/ServiceAccount
NAME AGE
cilium 3d5h
cilium-envoy 3d5h
cilium-operator 3d5h
hubble-relay 3d5h
hubble-ui 3d5h

==> v1/Secret
NAME TYPE DATA AGE
cilium-ca Opaque 2 3d5h
hubble-relay-client-certs kubernetes.io/tls 3 3d5h
hubble-server-certs kubernetes.io/tls 3 3d5h

==> v1/ClusterRole
NAME CREATED AT
cilium 2026-06-16T11:55:28Z
cilium-operator 2026-06-16T11:55:28Z
hubble-ui 2026-06-16T11:55:28Z

==> v1/Role
cilium-config-agent 2026-06-16T11:55:28Z
cilium-operator-tlsinterception-secrets 2026-06-16T15:23:54Z
cilium-operator-ztunnel 2026-06-16T15:23:54Z

==> v1/Service
NAME TYPE CLUSTER-IP EXTERNAL-IP PORT(S) AGE
cilium-envoy ClusterIP None 9964/TCP 3d1h
hubble-relay ClusterIP 10.96.204.216 80/TCP 3d5h
hubble-ui ClusterIP 10.104.156.249 80/TCP 3d5h
hubble-metrics ClusterIP None 9965/TCP 3d5h
hubble-peer ClusterIP 10.96.34.225 443/TCP 3d5h

==> v1/DaemonSet
NAME DESIRED CURRENT READY UP-TO-DATE AVAILABLE NODE SELECTOR AGE
cilium 4 4 4 4 4 kubernetes.io/os=linux 3d5h
cilium-envoy 4 4 4 4 4 kubernetes.io/os=linux 3d5h
cilium-node-init 4 4 4 4 4 kubernetes.io/os=linux 3d5h

==> v1/ConfigMap
NAME DATA AGE
cilium-config 164 3d5h
cilium-envoy-config 1 3d5h
cilium-operator-dashboard 1 3d5h
hubble-relay-config 1 3d5h
hubble-ui-nginx 1 3d5h
hubble-dashboard 1 3d5h
hubble-dns-namespace 1 3d5h
hubble-l7-http-metrics-by-workload 1 3d5h
hubble-network-overview-namespace 1 3d5h

==> v1/ClusterRoleBinding
NAME ROLE AGE
cilium ClusterRole/cilium 3d5h
cilium-operator ClusterRole/cilium-operator 3d5h
hubble-ui ClusterRole/hubble-ui 3d5h

==> v1/RoleBinding
NAME ROLE AGE
cilium-config-agent Role/cilium-config-agent 3d5h
cilium-operator-tlsinterception-secrets Role/cilium-operator-tlsinterception-secrets 3d1h
cilium-operator-ztunnel Role/cilium-operator-ztunnel 3d1h

==> v1/Pod(related)
NAME READY STATUS RESTARTS AGE
cilium-g5d4l 1/1 Running 0 33m
cilium-qfhdd 1/1 Running 0 34m
cilium-qpttr 1/1 Running 0 34m
cilium-w5b25 1/1 Running 0 32m
cilium-envoy-2ch75 1/1 Running 0 6h6m
cilium-envoy-5dbtq 1/1 Running 0 6h6m
cilium-envoy-6kznt 1/1 Running 0 6h6m
cilium-envoy-vk7sm 1/1 Running 0 6h6m
cilium-node-init-8n9cv 1/1 Running 0 6h6m
cilium-node-init-hkc47 1/1 Running 0 6h6m
cilium-node-init-p7m4s 1/1 Running 0 6h6m
cilium-node-init-pdfvc 1/1 Running 0 6h6m
cilium-operator-667f68d4c5-g7rnd 1/1 Running 0 6h6m
cilium-operator-667f68d4c5-srwwv 1/1 Running 0 6h6m
hubble-relay-758b8867dd-j22n4 1/1 Running 0 6h6m
hubble-ui-677bcd7f96-pjclv 2/2 Running 0 6h6m

==> v1/Deployment
NAME READY UP-TO-DATE AVAILABLE AGE
cilium-operator 2/2 2 2 3d5h
hubble-relay 1/1 1 1 3d5h
hubble-ui 1/1 1 1 3d5h

TEST SUITE: None
NOTES:
You have successfully installed Cilium with Hubble Relay and Hubble UI.

Your release version is 1.19.4.

For any further help, visit https://docs.cilium.io/en/v1.19/gettinghelp
Error: release: not found
NAME: oauth2-proxy
LAST DEPLOYED: Fri Jun 19 17:15:08 2026
NAMESPACE: oauth2-proxy
STATUS: pending-upgrade
REVISION: 2
DESCRIPTION: Preparing upgrade
RESOURCES:
==> v1/Secret
NAME TYPE DATA AGE
oauth2-proxy Opaque 3 4d5h

==> v1/ConfigMap
NAME DATA AGE
oauth2-proxy 1 4d5h

==> v1/Service
NAME TYPE CLUSTER-IP EXTERNAL-IP PORT(S) AGE
oauth2-proxy ClusterIP 10.102.71.177 80/TCP,44180/TCP 4d5h

==> v1/Deployment
NAME READY UP-TO-DATE AVAILABLE AGE
oauth2-proxy 1/1 1 1 4d5h

==> v1/Pod(related)
NAME READY STATUS RESTARTS AGE
oauth2-proxy-784495d7f8-jwtvf 1/1 Running 0 35m

==> v1/ServiceAccount
NAME AGE
oauth2-proxy 4d5h
