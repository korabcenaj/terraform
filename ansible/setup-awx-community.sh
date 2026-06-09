#!/usr/bin/env bash
# ===========================================================================
# setup-awx-community.sh — Import Community Playbooks into AWX
# ===========================================================================
#
# This script registers community Ansible playbook repos as AWX Projects
# and creates Job Templates so you can run them from the AWX UI.
#
# Prerequisites:
#   - AWX running and accessible at $AWX_HOST
#   - kubectl access to the cluster (for auto-detection)
#   - jq installed
#
# Usage:
#   ./setup-awx-community.sh
#
# What it does:
#   1. Creates an AWX Organization "Community" (if not exists)
#   2. Creates an Inventory "K8s Cluster" with your nodes
#   3. Creates a Machine Credential for SSH
#   4. Imports 10+ community playbook repos as AWX Projects
#   5. Creates Job Templates for each project's main playbook
# ===========================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration — auto-detected or override via env vars
# ---------------------------------------------------------------------------
AWX_HOST="${AWX_HOST:-awx.local.lan}"
AWX_USER="${AWX_USER:-admin}"
AWX_PASS="${AWX_PASS:-}"
AWX_ORG="${AWX_ORG:-Community}"
AWX_INVENTORY="${AWX_INVENTORY:-K8s Cluster}"
AWX_CREDENTIAL="${AWX_CREDENTIAL:-SSH Key - mena}"
ANSIBLE_USER="${ANSIBLE_USER:-mena}"
SSH_KEY_PATH="${SSH_KEY_PATH:-$HOME/.ssh/id_ed25519}"

# Detect AWX password from Kubernetes secret if not provided
if [ -z "$AWX_PASS" ]; then
    AWX_PASS=$(kubectl get secret awx-admin-password -n awx \
        -o jsonpath='{.data.password}' 2>/dev/null | base64 -d 2>/dev/null || echo "")
    if [ -z "$AWX_PASS" ]; then
        echo "ERROR: Cannot retrieve AWX admin password. Set AWX_PASS env var."
        exit 1
    fi
fi

AWX_BASE="https://${AWX_HOST}"
AUTH_HEADER="Authorization: Basic $(echo -n "${AWX_USER}:${AWX_PASS}" | base64)"

# ---------------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------------
awx_get() {
    curl -sk -H "${AUTH_HEADER}" -H "Content-Type: application/json" "$@"
}

awx_post() {
    curl -sk -X POST -H "${AUTH_HEADER}" -H "Content-Type: application/json" "$@"
}

awx_patch() {
    curl -sk -X PATCH -H "${AUTH_HEADER}" -H "Content-Type: application/json" "$@"
}

get_or_create() {
    local name="$1" url="$2" payload="$3"
    local existing
    existing=$(awx_get "${AWX_BASE}${url}?name=${name}" | jq -r '.results[0].id // empty')
    if [ -n "$existing" ]; then
        echo "  [EXISTS] $name (id=$existing)"
        echo "$existing"
    else
        local id
        id=$(awx_post "${AWX_BASE}${url}" -d "$payload" | jq -r '.id // empty')
        if [ -z "$id" ]; then
            echo "  [ERROR]  Failed to create $name"
            return 1
        fi
        echo "  [CREATED] $name (id=$id)"
        echo "$id"
    fi
}

echo "============================================================================"
echo " AWX Community Playbooks Setup"
echo " Target: ${AWX_BASE}"
echo " Organization: ${AWX_ORG}"
echo "============================================================================"

# ---------------------------------------------------------------------------
# Step 1: Create Organization
# ---------------------------------------------------------------------------
echo ""
echo "[1/5] Setting up Organization..."
ORG_ID=$(get_or_create "$AWX_ORG" "/api/v2/organizations/" \
    "{\"name\":\"${AWX_ORG}\",\"description\":\"Community Ansible playbooks imported from GitHub\"}")

# ---------------------------------------------------------------------------
# Step 2: Create Inventory
# ---------------------------------------------------------------------------
echo ""
echo "[2/5] Setting up Inventory..."
INV_ID=$(get_or_create "$AWX_INVENTORY" "/api/v2/inventories/" \
    "{\"name\":\"${AWX_INVENTORY}\",\"organization\":${ORG_ID},\"description\":\"Kubernetes cluster nodes\"}")

# Add hosts if inventory is empty
HOST_COUNT=$(awx_get "${AWX_BASE}/api/v2/inventories/${INV_ID}/hosts/" | jq '.count')
if [ "$HOST_COUNT" -eq 0 ]; then
    echo "  Adding hosts to inventory..."
    
    declare -A HOST_USERS
    HOST_USERS=(
        ["k8s-master.local.lan"]="mena"
        ["k8s.local.lan"]="kub"
        ["k8s2.local.lan"]="kub"
    )
    
    for host in "${!HOST_USERS[@]}"; do
        host_user="${HOST_USERS[$host]}"
        # Try to resolve IP; fall back to hardcoded
        ip=$(getent hosts "$host" 2>/dev/null | awk '{print $1}' || echo "")
        host_vars="{\"ansible_user\":\"${host_user}\"}"
        [ -n "$ip" ] && host_vars="{\"ansible_user\":\"${host_user}\",\"ansible_host\":\"${ip}\"}"
        
        awx_post "${AWX_BASE}/api/v2/inventories/${INV_ID}/hosts/" \
            -d "{\"name\":\"${host}\",\"variables\":\"$(echo "$host_vars" | jq -c .)\"}" \
            > /dev/null 2>&1
        echo "    Added: $host"
    done
fi

# ---------------------------------------------------------------------------
# Step 3: Create SSH Credential
# ---------------------------------------------------------------------------
echo ""
echo "[3/5] Setting up Machine Credential..."

# Check if SSH key exists
if [ ! -f "$SSH_KEY_PATH" ]; then
    echo "  [WARN]  SSH key not found at $SSH_KEY_PATH"
    echo "  [WARN]  Create credential manually in AWX UI: Credentials → Add → Machine"
    CRED_ID=""
else
    SSH_KEY_DATA=$(cat "$SSH_KEY_PATH")
    CRED_PAYLOAD=$(jq -n \
        --arg name "$AWX_CREDENTIAL" \
        --arg org "$ORG_ID" \
        --arg user "$ANSIBLE_USER" \
        --arg key "$SSH_KEY_DATA" \
        '{
            name: $name,
            organization: ($org|tonumber),
            credential_type: 1,
            inputs: {
                username: $user,
                ssh_key_data: $key
            }
        }')
    
    CRED_ID=$(awx_post "${AWX_BASE}/api/v2/credentials/" -d "$CRED_PAYLOAD" | jq -r '.id // empty')
    if [ -n "$CRED_ID" ]; then
        echo "  [CREATED] $AWX_CREDENTIAL (id=$CRED_ID)"
    else
        echo "  [WARN]  Could not create credential — may already exist"
        CRED_ID=$(awx_get "${AWX_BASE}/api/v2/credentials/?name=${AWX_CREDENTIAL}" | jq -r '.results[0].id // empty')
        [ -n "$CRED_ID" ] && echo "  [EXISTS] $AWX_CREDENTIAL (id=$CRED_ID)"
    fi
fi

# ---------------------------------------------------------------------------
# Step 4: Create Projects from Community Repos
# ---------------------------------------------------------------------------
echo ""
echo "[4/5] Importing Community Playbook Repos as AWX Projects..."

declare -A PROJECTS
PROJECTS=(
    # Priority 1 — Security
    ["UBUNTU22-CIS"]="https://github.com/ansible-lockdown/UBUNTU22-CIS.git"
    
    # Priority 2 — Monitoring
    ["Node Exporter"]="https://github.com/cloudalchemy/ansible-node-exporter.git"
    
    # Priority 3 — Web/SSL
    ["NGINX Official"]="https://github.com/nginxinc/ansible-role-nginx.git"
    ["Certbot (Let's Encrypt)"]="https://github.com/geerlingguy/ansible-role-certbot.git"
    
    # Priority 4 — System Maintenance
    ["System Update"]="https://github.com/robertdebock/ansible-role-update.git"
    ["Fail2ban"]="https://github.com/robertdebock/ansible-role-fail2ban.git"
    ["Bootstrap"]="https://github.com/robertdebock/ansible-role-bootstrap.git"
    
    # Priority 5 — Container Runtime
    ["Docker CE"]="https://github.com/geerlingguy/ansible-role-docker.git"
    
    # Priority 6 — Storage
    ["NFS"]="https://github.com/geerlingguy/ansible-role-nfs.git"
    
    # Priority 7 — Observability
    ["Prometheus Stack"]="https://github.com/cloudalchemy/ansible-prometheus.git"
    
    # Reference
    ["Ansible for DevOps"]="https://github.com/geerlingguy/ansible-for-devops.git"
)

for proj_name in "${!PROJECTS[@]}"; do
    repo_url="${PROJECTS[$proj_name]}"
    echo "  → $proj_name ($repo_url)"
    
    proj_payload=$(jq -n \
        --arg name "$proj_name" \
        --arg org "$ORG_ID" \
        --arg url "$repo_url" \
        '{
            name: $name,
            organization: ($org|tonumber),
            scm_type: "git",
            scm_url: $url,
            scm_update_on_launch: true,
            scm_update_cache_timeout: 3600
        }')
    
    proj_id=$(awx_post "${AWX_BASE}/api/v2/projects/" -d "$proj_payload" | jq -r '.id // empty')
    if [ -n "$proj_id" ]; then
        echo "    Project ID: $proj_id"
    else
        echo "    [SKIP] May already exist"
    fi
done

# ---------------------------------------------------------------------------
# Step 5: Create Job Templates for Key Playbooks
# ---------------------------------------------------------------------------
echo ""
echo "[5/5] Creating Job Templates..."

declare -A JOBS
# Format: "Job Name|Project Name|Playbook File"
JOBS=(
    ["CIS Hardening - Level 1|UBUNTU22-CIS|default.yml"]=1
    ["CIS Hardening - Level 2|UBUNTU22-CIS|level2.yml"]=1
    ["Install Node Exporter|Node Exporter|site.yml"]=1
    ["Configure NGINX|NGINX Official|defaults/main.yml"]=1
    ["Install Certbot|Certbot (Let's Encrypt)|defaults/main.yml"]=1
    ["System Update (All)|System Update|tasks/main.yml"]=1
    ["Configure Fail2ban|Fail2ban|tasks/main.yml"]=1
    ["Bootstrap Node|Bootstrap|tasks/main.yml"]=1
    ["Install Docker CE|Docker CE|defaults/main.yml"]=1
    ["Configure NFS|NFS|defaults/main.yml"]=1
    ["Deploy Prometheus Stack|Prometheus Stack|site.yml"]=1
)

for job_key in "${!JOBS[@]}"; do
    IFS='|' read -r job_name proj_name playbook <<< "$job_key"
    
    # Get project ID
    proj_id=$(awx_get "${AWX_BASE}/api/v2/projects/?name=${proj_name}" | jq -r '.results[0].id // empty')
    if [ -z "$proj_id" ]; then
        echo "  [SKIP]  $job_name (project '$proj_name' not found)"
        continue
    fi
    
    # Wait for project to sync (only first time check)
    # (In production, you'd poll the project status)
    
    jt_payload=$(jq -n \
        --arg name "$job_name" \
        --arg inv "$INV_ID" \
        --arg proj "$proj_id" \
        --arg playbook "$playbook" \
        '{
            name: $name,
            inventory: ($inv|tonumber),
            project: ($proj|tonumber),
            playbook: $playbook,
            job_type: "run",
            become_enabled: true,
            verbosity: 2
        }')
    
    # Add credential if we have one
    if [ -n "${CRED_ID:-}" ] && [ "$CRED_ID" != "null" ]; then
        jt_payload=$(echo "$jt_payload" | jq --arg cred "$CRED_ID" '. + {credentials: [($cred|tonumber)]}')
    fi
    
    jt_id=$(awx_post "${AWX_BASE}/api/v2/job_templates/" -d "$jt_payload" | jq -r '.id // empty')
    if [ -n "$jt_id" ]; then
        echo "  [CREATED] $job_name (id=$jt_id)"
    else
        echo "  [SKIP]   $job_name (may already exist)"
    fi
done

echo ""
echo "============================================================================"
echo " SETUP COMPLETE"
echo "============================================================================"
echo ""
echo " Open AWX:  https://${AWX_HOST}"
echo " Username:  ${AWX_USER}"
echo ""
echo " Next steps:"
echo "   1. Go to Projects → sync each project (SCM update)"
echo "   2. Go to Templates → launch any job template"
echo "   3. For roles (not full playbooks), create a wrapper playbook:"
echo ""
echo "      ---"
echo "      - hosts: all"
echo "        roles:"
echo "          - { role: geerlingguy.docker }"
echo ""
echo "   The 'Ansible for DevOps' project has many ready-to-run examples."
echo "============================================================================"
