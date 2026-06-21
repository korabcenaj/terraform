# Migration Plan: ArgoCD → FluxCD + Keycloak → Zitadel

## 1. ArgoCD → FluxCD (saves ~1.2 Gi)

### Current State
- 38 ArgoCD applications, 30 healthy
- Sources: 25 Git repos on git.local.lan/gitea, 13 Helm chart repos
- ArgoCD namespace: argocd (7 pods, ~1.2 Gi memory)

### FluxCD Architecture (replacement)
```
flux-system/
├── gitrepository/    → points to your Git repos
├── kustomization/    → syncs manifests from Git
└── helmrelease/      → manages Helm charts
```

### Migration Steps

**Phase 1: Install Flux (no impact)**
```bash
flux bootstrap git \
  --url=https://git.local.lan/gitea/argocd-cluster-config.git \
  --branch=main \
  --path=clusters/homelab \
  --namespace=flux-system
```

**Phase 2: Convert ArgoCD apps to Flux resources**
For each ArgoCD app, create one of:

| ArgoCD source type | Flux equivalent |
|---|---|
| Git repo → path | `Kustomization` with `GitRepository` |
| Helm chart repo | `HelmRelease` with `HelmRepository` |
| Kustomize overlay | `Kustomization` with `path` + `dependsOn` |

**Phase 3: Cutover (5 min downtime)**
```bash
# Scale ArgoCD to 0, let Flux take over
kubectl scale deploy -n argocd --all --replicas=0
```

**Phase 4: Delete ArgoCD (after verification)**
```bash
helm uninstall argocd -n argocd
kubectl delete ns argocd --force
```

### Risk: LOW — Flux can run alongside ArgoCD during migration. Apps managed by both won't conflict if Flux uses server-side apply.

---

## 2. Keycloak → Zitadel (saves ~400 Mi)

### Current Dependencies (what breaks if we cut Keycloak)
| Client | Service | Impact |
|--------|---------|--------|
| oauth2-proxy | auth.local.lan | All SSO-protected apps inaccessible |
| grafana | Grafana OIDC | Grafana login broken |
| argo-cd | ArgoCD OIDC | ArgoCD login broken |
| harbor | Harbor OIDC | Harbor login broken |
| matrix-synapse | Matrix OIDC | Matrix login broken |

### Zitadel Architecture
```
zitadel/
├── Organization: homelab
│   └── Project: platform
│       ├── App: oauth2-proxy    → client_id + secret
│       ├── App: grafana         → client_id + secret
│       ├── App: argocd          → client_id + secret
│       ├── App: harbor          → client_id + secret
│       └── App: matrix-synapse  → client_id + secret
```

### Migration Steps

**Phase 1: Deploy Zitadel alongside Keycloak (no impact)**
```bash
helm repo add zitadel https://charts.zitadel.com
helm install zitadel zitadel/zitadel \
  -n zitadel --create-namespace \
  --set zitadel.masterkey=... \
  --set replicaCount=1
```
Zitadel will run at ~80 Mi vs Keycloak's 472 Mi.

**Phase 2: Create organization and clients in Zitadel**
Via Zitadel API/UI:
1. Create org "homelab"
2. Create project "platform"  
3. Create 5 OIDC applications → get client_id/secret for each

**Phase 3: Migrate services one-by-one (rolling, each takes ~2 min)**
```
Service          Config to update
───────────────  ──────────────────────────────────
oauth2-proxy     helm values: oidc_issuer_url → Zitadel
Grafana          helm values: grafana.ini auth.generic_oauth
ArgoCD           helm values: oidc.config issuer + clientSecret  
Harbor           helm values: oidc provider config
Matrix           deployment env: OIDC_ISSUER
```

**Phase 4: Delete Keycloak**
```bash
helm uninstall keycloak -n keycloak
# Saves 472 Mi immediately
```

### Risk: MEDIUM — SSO is critical. Do Phase 3 one service at a time, verify login before moving to next. Keep Keycloak running as fallback until all services verified.

---

## Execution Order (recommended)

```
Day 1: ArgoCD → FluxCD (lower risk, bigger savings)
  1. Install Flux
  2. Convert apps (can batch by repo)
  3. Verify Flux reconciles
  4. Delete ArgoCD

Day 2: Keycloak → Zitadel (higher risk, smaller savings)  
  1. Deploy Zitadel
  2. Create org + clients
  3. Migrate oauth2-proxy first (gateway for everything)
  4. Migrate Grafana, Harbor, Matrix
  5. Migrate ArgoCD (or skip if already on Flux)
  6. Delete Keycloak

Total savings: ~1.6 Gi  |  k8s-master would drop from 62% to ~35%
```
