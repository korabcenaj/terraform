#!/usr/bin/env python3
"""Generate a static deployment dashboard for Terraform + Kubernetes apps.

Patches applied vs original version:
  1. ANSI escape codes are stripped from all CLI output before it appears in
     the dashboard so error messages are readable without terminal rendering.
  2. kubectl cluster-unreachable errors are replaced with a concise human
     hint that explains the most likely cause (missing kubeconfig or no
     cluster access) instead of dumping raw memcache/connection-refused logs.
"""

from __future__ import annotations

import datetime as dt
import json
import os
import re
import subprocess
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parents[1]
DASHBOARD_DIR = REPO_ROOT / "dashboard"
DATA_PATH = DASHBOARD_DIR / "data.json"
HTML_PATH = DASHBOARD_DIR / "index.html"

# ── App catalogue ─────────────────────────────────────────────────────────────
# kind: application | platform | policy | infra | security | media | observability
APP_METADATA: dict[str, dict[str, Any]] = {
    # Applications
    "portfolio":        {"kind": "application", "namespace": "portfolio",     "service": "portfolio-web",   "port": 80},
    "jellyfin":         {"kind": "media",        "namespace": "jellyfin",      "service": "jellyfin",        "port": 8096},
    "qbittorrent":      {"kind": "media",        "namespace": "qbittorrent",   "service": "qbittorrent",     "port": 8080},
    "pihole":           {"kind": "application",  "namespace": "pihole",        "service": "pihole",          "port": 80},
    "sonarr":           {"kind": "media",        "namespace": "sonarr",        "service": "sonarr",          "port": 8989},
    "radarr":           {"kind": "media",        "namespace": "radarr",        "service": "radarr",          "port": 7878},
    # Platform / infra
    "monitoring":               {"kind": "observability", "namespace": "monitoring",    "service": "grafana",         "port": 3000},
    "metrics_server":           {"kind": "platform",      "namespace": "kube-system",   "service": "metrics-server",  "port": 443},
    "cert_manager":             {"kind": "infra",         "namespace": "cert-manager",  "service": "cert-manager",    "port": 9402},
    "ingress_nginx":            {"kind": "infra",         "namespace": "ingress-nginx", "service": "ingress-nginx",   "port": 80},
    "caddy":                    {"kind": "infra",         "namespace": "caddy-system",  "service": "caddy",           "port": 443},
    "kube_prometheus_stack":    {"kind": "observability", "namespace": "monitoring",    "service": "prometheus",      "port": 9090},
    "loki":                     {"kind": "observability", "namespace": "loki",          "service": "loki",            "port": 3100},
    "minio":                    {"kind": "infra",         "namespace": "minio",         "service": "minio",           "port": 9000},
    "velero":                   {"kind": "infra",         "namespace": "velero",        "service": "velero",          "port": "n/a"},
    "vault":                    {"kind": "security",      "namespace": "vault",         "service": "vault",           "port": 8200},
    "external_secrets":         {"kind": "security",      "namespace": "external-secrets", "service": "external-secrets", "port": "n/a"},
    "argocd":                   {"kind": "platform",      "namespace": "argocd",        "service": "argocd-server",   "port": 443},
    "argo_rollouts":            {"kind": "platform",      "namespace": "argo-rollouts", "service": "argo-rollouts",   "port": "n/a"},
    "tempo":                    {"kind": "observability", "namespace": "tempo",         "service": "tempo",           "port": 3200},
    "oauth2_proxy":             {"kind": "security",      "namespace": "oauth2-proxy",  "service": "oauth2-proxy",    "port": 4180},
    "kyverno":                  {"kind": "security",      "namespace": "kyverno",       "service": "kyverno",         "port": "n/a"},
    "keycloak":                 {"kind": "security",      "namespace": "keycloak",      "service": "keycloak",        "port": 8080},
    "gpu_device_plugins":       {"kind": "platform",      "namespace": "kube-system",   "service": "n/a",             "port": "n/a"},
    "gpu_priority_classes":     {"kind": "policy",        "namespace": "all",           "service": "n/a",             "port": "n/a"},
    # Policies
    "network_policies":         {"kind": "policy", "namespace": "all", "service": "n/a", "port": "n/a"},
    "resource_quotas":          {"kind": "policy", "namespace": "all", "service": "n/a", "port": "n/a"},
    "pod_disruption_budgets":   {"kind": "policy", "namespace": "all", "service": "n/a", "port": "n/a"},
    "slo_alerts":               {"kind": "observability", "namespace": "monitoring", "service": "n/a", "port": "n/a"},
}

APP_ORDER = list(APP_METADATA)

# ── ANSI stripping ────────────────────────────────────────────────────────────
_ANSI_RE = re.compile(r"\x1b\[[0-9;]*[mGKHF]")


def strip_ansi(text: str) -> str:
    """Remove ANSI escape sequences from CLI output."""
    return _ANSI_RE.sub("", text)


# ── kubectl connectivity hint ─────────────────────────────────────────────────
_REFUSED_PATTERNS = (
    "connection refused",
    "connect: connection refused",
    "no such host",
    "unable to connect to the server",
    "memcache.go",
    "dial tcp",
)

def kubectl_hint(raw_stderr: str) -> str:
    """Replace noisy kubectl connection errors with a human-readable hint."""
    lower = raw_stderr.lower()
    if any(p in lower for p in _REFUSED_PATTERNS):
        kubeconfig = os.environ.get("KUBECONFIG", str(Path.home() / ".kube" / "config"))
        if not Path(kubeconfig).exists():
            return (
                "kubectl: no kubeconfig found at "
                f"{kubeconfig} — set KUBECONFIG or copy your cluster config there."
            )
        return (
            "kubectl: cluster unreachable — check that the API server is "
            "reachable and the kubeconfig context is correct "
            f"(config: {kubeconfig})."
        )
    return strip_ansi(raw_stderr).strip() or "kubectl: unknown error"


# ── CLI helpers ───────────────────────────────────────────────────────────────
def run_cmd(cmd: list[str], cwd: Path) -> tuple[int, str, str]:
    try:
        proc = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, check=False)
        return proc.returncode, proc.stdout.strip(), proc.stderr.strip()
    except FileNotFoundError as exc:
        tool = cmd[0]
        return 127, "", f"{tool}: command not found — install it first."


def get_terraform_outputs() -> tuple[dict[str, Any], str]:
    code, out, err = run_cmd(["terraform", "output", "-json"], REPO_ROOT)
    if code != 0:
        return {}, f"terraform: {strip_ansi(err or 'output unavailable — run terraform init/apply first.')}"
    try:
        return json.loads(out), "ok"
    except json.JSONDecodeError as exc:
        return {}, f"terraform: invalid JSON from output ({exc})"


def get_k8s_namespaces() -> tuple[set[str], str]:
    """Return set of active namespace names and a status string."""
    code, out, err = run_cmd(
        ["kubectl", "get", "namespaces", "-o", "json"], REPO_ROOT
    )
    if code != 0:
        return set(), kubectl_hint(err)
    try:
        data = json.loads(out)
        names = {
            item["metadata"]["name"]
            for item in data.get("items", [])
        }
        return names, "ok"
    except (json.JSONDecodeError, KeyError):
        return set(), "kubectl: unexpected response format"


def get_k8s_deployments() -> tuple[dict[str, Any], str]:
    code, out, err = run_cmd(
        ["kubectl", "get", "deployments", "-A", "-o", "json"], REPO_ROOT
    )
    if code != 0:
        return {}, kubectl_hint(err)
    try:
        return json.loads(out), "ok"
    except json.JSONDecodeError:
        return {}, "kubectl: invalid JSON from deployments query"


def summarize_k8s_by_namespace(
    payload: dict[str, Any],
) -> dict[str, dict[str, int]]:
    summary: dict[str, dict[str, int]] = {}
    for item in payload.get("items", []):
        md = item.get("metadata", {})
        st = item.get("status", {})
        namespace = md.get("namespace", "default")
        ready = int(st.get("readyReplicas") or 0)
        desired = int(st.get("replicas") or 0)
        bucket = summary.setdefault(
            namespace,
            {"deployments": 0, "ready_replicas": 0, "desired_replicas": 0},
        )
        bucket["deployments"] += 1
        bucket["ready_replicas"] += ready
        bucket["desired_replicas"] += desired
    return summary


# ── Config parsing ────────────────────────────────────────────────────────────
def parse_enable_defaults() -> dict[str, bool]:
    variables_tf = REPO_ROOT / "variables.tf"
    if not variables_tf.exists():
        return {}
    text = variables_tf.read_text(encoding="utf-8")
    pattern = re.compile(
        r'variable\s+"(?P<name>enable_[a-z0-9_]+)"\s*\{(?P<body>.*?)\}',
        re.DOTALL,
    )
    result: dict[str, bool] = {}
    for m in pattern.finditer(text):
        dm = re.search(r"default\s*=\s*(true|false)", m.group("body"))
        if dm:
            result[m.group("name")] = dm.group(1) == "true"
    return result


def parse_tfvars_enable_flags() -> dict[str, bool]:
    candidates = [
        REPO_ROOT / "local.auto.tfvars",
        REPO_ROOT / "terraform.tfvars",
        REPO_ROOT / "terraform.tfvars.example",
    ]
    result: dict[str, bool] = {}
    for file_path in candidates:
        if not file_path.exists():
            continue
        for line in file_path.read_text(encoding="utf-8").splitlines():
            clean = line.split("#", 1)[0].strip()
            m = re.match(r"^(enable_[a-z0-9_]+)\s*=\s*(true|false)\s*$", clean)
            if m:
                result[m.group(1)] = m.group(2) == "true"
        break  # use the first file found (most specific wins)
    return result


def normalize_enabled_flags() -> dict[str, bool]:
    merged = {**parse_enable_defaults(), **parse_tfvars_enable_flags()}
    normalized = {k.removeprefix("enable_"): v for k, v in merged.items()}
    for app in APP_ORDER:
        normalized.setdefault(app, False)
    return normalized


# ── Status classification ─────────────────────────────────────────────────────
def classify_app(
    app: str,
    enabled: dict[str, bool],
    tf_outputs: dict[str, Any],
    ns_summary: dict[str, dict[str, int]],
    active_ns: set[str],
) -> dict[str, Any]:
    meta = APP_METADATA[app]
    configured = enabled.get(app, False)
    tf_deployed = tf_outputs.get("deployed_modules", {}).get("value", {}).get(app)
    namespace = meta["namespace"]

    if namespace == "all":
        k8s: dict[str, Any] = {"deployments": None, "ready_replicas": None, "desired_replicas": None}
    elif namespace in ns_summary:
        k8s = ns_summary[namespace]
    elif namespace in active_ns:
        k8s = {"deployments": 0, "ready_replicas": 0, "desired_replicas": 0}
    else:
        k8s = {"deployments": 0, "ready_replicas": 0, "desired_replicas": 0}

    ns_exists = namespace in active_ns or namespace == "all"
    dep_count = k8s.get("deployments") or 0

    if tf_deployed is True and dep_count > 0:
        health = "running"
    elif ns_exists and dep_count == 0 and configured:
        health = "provisioning"
    elif configured:
        health = "planned"
    else:
        health = "disabled"

    return {
        "name": app,
        "kind": meta["kind"],
        "namespace": namespace,
        "service": str(meta["service"]),
        "port": str(meta["port"]),
        "configured": configured,
        "terraform_deployed": tf_deployed,
        "kubernetes": k8s,
        "health": health,
    }


# ── HTML template ─────────────────────────────────────────────────────────────
def render_html(data: dict[str, Any]) -> str:
    payload_json = json.dumps(data, ensure_ascii=True)

    # Kind → badge colour class
    kind_colours = {
        "application":   "#dbeafe:#1d4ed8",
        "media":         "#ede9fe:#6d28d9",
        "platform":      "#e0f2fe:#0369a1",
        "infra":         "#fef9c3:#92400e",
        "security":      "#fee2e2:#b91c1c",
        "observability": "#d1fae5:#065f46",
        "policy":        "#e5e7eb:#374151",
    }
    kind_css = "\n".join(
        f"    .kind-{k} {{ background: {v.split(':')[0]}; color: {v.split(':')[1]}; }}"
        for k, v in kind_colours.items()
    )

    return f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Homelab Deployment Dashboard</title>
  <style>
    :root {{
      --bg: #f7f3eb; --ink: #1f2937; --card: #fffdf8;
      --ok: #15803d; --warn: #b45309; --off: #6b7280; --danger: #b91c1c;
    }}
    * {{ box-sizing: border-box; }}
    body {{
      margin: 0; padding: 20px;
      font-family: "IBM Plex Sans","Noto Sans",sans-serif;
      color: var(--ink);
      background:
        radial-gradient(circle at 12% 12%, rgba(15,118,110,.12), transparent 40%),
        radial-gradient(circle at 80% 8%, rgba(234,179,8,.10), transparent 35%),
        var(--bg);
      min-height: 100vh;
    }}
    .shell {{ max-width: 1200px; margin: 0 auto; }}
    .hero {{
      background: linear-gradient(120deg,#0f766e,#155e75);
      color: #f8fafc; border-radius: 16px; padding: 22px 26px;
      box-shadow: 0 16px 32px rgba(0,0,0,.15);
    }}
    .hero h1 {{ margin: 0; font-size: 1.75rem; }}
    .hero p {{ margin: 6px 0 0; opacity: .9; font-size: .97rem; }}
    .summary-grid {{
      margin: 16px 0;
      display: grid;
      grid-template-columns: repeat(auto-fit,minmax(160px,1fr));
      gap: 10px;
    }}
    .tile {{
      background: var(--card); border: 1px solid #e8dfcf;
      border-radius: 12px; padding: 12px 14px;
      box-shadow: 0 6px 16px rgba(30,41,59,.05);
    }}
    .tile .k {{ color: var(--off); font-size: .78rem; text-transform: uppercase; letter-spacing: .06em; }}
    .tile .v {{ font-size: 1.3rem; font-weight: 700; margin-top: 4px; }}
    .panel {{
      background: var(--card); border-radius: 12px;
      border: 1px solid #e8dfcf; overflow: hidden;
      box-shadow: 0 6px 16px rgba(30,41,59,.05);
    }}
    .filter-bar {{ display: flex; gap: 8px; flex-wrap: wrap; padding: 12px 14px; background: #f5efe2; }}
    .filter-btn {{
      border: 1px solid #d4cbb8; background: #fff; border-radius: 999px;
      padding: 4px 12px; font-size: .8rem; cursor: pointer; transition: all .15s;
    }}
    .filter-btn.active, .filter-btn:hover {{ background: #0f766e; color: #fff; border-color: #0f766e; }}
    table {{ width: 100%; border-collapse: collapse; }}
    thead th {{
      background: #f5efe2; color: #374151; font-size: .78rem;
      text-align: left; text-transform: uppercase; letter-spacing: .05em; padding: 10px 12px;
    }}
    tbody tr {{ transition: background .1s; }}
    tbody tr:hover {{ background: #fdf8f0; }}
    tbody td {{ border-top: 1px solid #efe7d9; padding: 9px 12px; font-size: .9rem; vertical-align: middle; }}
    .badge {{
      display: inline-flex; align-items: center; border-radius: 999px;
      padding: 3px 10px; font-weight: 600; font-size: .73rem;
      text-transform: uppercase; letter-spacing: .04em;
    }}
    .running     {{ background: #dcfce7; color: var(--ok); }}
    .planned     {{ background: #fef3c7; color: var(--warn); }}
    .provisioning {{ background: #fed7aa; color: #c2410c; }}
    .disabled    {{ background: #e5e7eb; color: var(--off); }}
{kind_css}
    .source-bar {{ color: var(--off); font-size: .82rem; margin-top: 10px; padding: 0 4px; }}
    .source-bar .ok   {{ color: var(--ok); font-weight: 600; }}
    .source-bar .fail {{ color: var(--danger); font-weight: 600; }}
    @keyframes rise {{ from {{ opacity:0;transform:translateY(8px)}} to {{opacity:1;transform:none}} }}
    .hero,.tile,.panel {{ animation: rise .4s ease-out; }}
    @media(max-width:760px){{
      body{{padding:12px;}} .hero h1{{font-size:1.4rem;}}
      tbody td,thead th{{padding:7px 9px;}}
    }}
  </style>
</head>
<body>
<main class="shell">
  <section class="hero">
    <h1>Homelab Deployment Dashboard</h1>
    <p>Live snapshot from Terraform state and Kubernetes API.</p>
  </section>
  <section class="summary-grid" id="summary-grid"></section>
  <section class="panel">
    <div class="filter-bar" id="filter-bar"></div>
    <table>
      <thead>
        <tr>
          <th>Module</th><th>Kind</th><th>Status</th>
          <th>Configured</th><th>Terraform</th><th>K8s Replicas</th><th>Endpoint</th>
        </tr>
      </thead>
      <tbody id="apps-body"></tbody>
    </table>
  </section>
  <p class="source-bar" id="source-bar"></p>
</main>
<script>
const DATA = {payload_json};

function badge(cls, label) {{
  return '<span class="badge ' + cls + '">' + label + '</span>';
}}

const apps = DATA.apps || [];

// Summary tiles
const counts = {{running:0, planned:0, provisioning:0, disabled:0}};
apps.forEach(a => counts[a.health] = (counts[a.health]||0)+1);
const grid = document.getElementById('summary-grid');
[
  ['Cluster', DATA.cluster || 'home-lab'],
  ['Snapshot', (DATA.generated_at||'').replace('T',' ').replace('+00:00',' UTC')],
  ['Running', counts.running],
  ['Planned', counts.planned],
  ['Provisioning', counts.provisioning],
  ['Disabled', counts.disabled],
].forEach(([k,v]) => {{
  const t = document.createElement('article');
  t.className = 'tile';
  t.innerHTML = '<div class="k">'+k+'</div><div class="v">'+v+'</div>';
  grid.appendChild(t);
}});

// Filter buttons
const kinds = [...new Set(apps.map(a=>a.kind))].sort();
const fb = document.getElementById('filter-bar');
let activeKind = null;
function buildFilter() {{
  fb.innerHTML = '';
  ['all',...kinds].forEach(k => {{
    const btn = document.createElement('button');
    btn.className = 'filter-btn' + (k===activeKind||(!activeKind&&k==='all')?' active':'');
    btn.textContent = k;
    btn.onclick = () => {{ activeKind = k==='all'?null:k; buildFilter(); renderRows(); }};
    fb.appendChild(btn);
  }});
}}

// Table rows
const tbody = document.getElementById('apps-body');
function renderRows() {{
  tbody.innerHTML = '';
  (activeKind ? apps.filter(a=>a.kind===activeKind) : apps).forEach(app => {{
    const k8s = app.kubernetes || {{}};
    const rep = (k8s.ready_replicas==null||k8s.desired_replicas==null)
      ? 'n/a'
      : k8s.ready_replicas+'/'+k8s.desired_replicas+' pods';
    const ep = app.service==='n/a' ? 'n/a'
      : app.namespace+'/'+app.service+':'+app.port;
    const tfVal = app.terraform_deployed===null||app.terraform_deployed===undefined
      ? '<span style="color:var(--off)">unknown</span>'
      : app.terraform_deployed
        ? '<span style="color:var(--ok)">applied</span>'
        : '<span style="color:var(--warn)">not applied</span>';
    const tr = document.createElement('tr');
    tr.innerHTML =
      '<td><strong>'+app.name+'</strong></td>'+
      '<td><span class="badge kind-'+app.kind+'">'+app.kind+'</span></td>'+
      '<td>'+badge(app.health, app.health)+'</td>'+
      '<td>'+(app.configured?'<span style="color:var(--ok)">enabled</span>':'<span style="color:var(--off)">disabled</span>')+'</td>'+
      '<td>'+tfVal+'</td>'+
      '<td>'+rep+'</td>'+
      '<td style="font-size:.82rem;color:var(--off)">'+ep+'</td>';
    tbody.appendChild(tr);
  }});
}}

buildFilter();
renderRows();

// Source bar
const sb = document.getElementById('source-bar');
function srcSpan(label, status) {{
  const ok = status==='ok';
  return label+': <span class="'+(ok?'ok':'fail')+'">'+(ok?'ok':status)+'</span>';
}}
sb.innerHTML = [
  srcSpan('terraform', DATA.sources.terraform),
  srcSpan('kubectl', DATA.sources.kubectl),
  'tfvars: '+DATA.sources.tfvars,
].join(' &nbsp;|&nbsp; ');
</script>
</body>
</html>
"""


# ── Main ──────────────────────────────────────────────────────────────────────
def main() -> None:
    enabled = normalize_enabled_flags()
    tf_outputs, tf_status = get_terraform_outputs()
    active_ns, kubectl_status = get_k8s_namespaces()
    k8s_payload, k8s_dep_status = get_k8s_deployments()
    ns_summary = summarize_k8s_by_namespace(k8s_payload)

    # Merge kubectl status (prefer namespace status as primary signal)
    if kubectl_status != "ok":
        final_kubectl_status = kubectl_status
    else:
        final_kubectl_status = k8s_dep_status if k8s_dep_status != "ok" else "ok"

    apps = [
        classify_app(app, enabled, tf_outputs, ns_summary, active_ns)
        for app in APP_ORDER
    ]

    cluster_name = tf_outputs.get("cluster_name", {}).get("value", "home-lab")
    tfvars_sources = [
        "local.auto.tfvars", "terraform.tfvars", "terraform.tfvars.example"
    ]
    tfvars_source = next(
        (s for s in tfvars_sources if (REPO_ROOT / s).exists()), "none"
    )

    payload = {
        "generated_at": dt.datetime.now(dt.UTC).replace(microsecond=0).isoformat(),
        "cluster": cluster_name,
        "apps": apps,
        "sources": {
            "terraform": tf_status,
            "kubectl": final_kubectl_status,
            "tfvars": tfvars_source,
        },
    }

    DASHBOARD_DIR.mkdir(parents=True, exist_ok=True)
    DATA_PATH.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    HTML_PATH.write_text(render_html(payload), encoding="utf-8")

    print(f"Dashboard  : {HTML_PATH}")
    print(f"Data       : {DATA_PATH}")
    print(f"terraform  : {tf_status}")
    print(f"kubectl    : {final_kubectl_status}")


if __name__ == "__main__":
    main()
