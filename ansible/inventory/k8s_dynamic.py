#!/usr/bin/env python3
"""
Dynamic Ansible inventory for Kubernetes nodes.

Reads nodes from the Kubernetes API and produces an Ansible-compatible
inventory JSON.  Falls back to the static inventory if kubectl is not
available or the cluster is unreachable.

Usage:
  ansible-inventory -i inventory/k8s_dynamic.py --list
  ansible-playbook -i inventory/k8s_dynamic.py playbooks/node-audit.yml
"""

import json
import os
import subprocess
import sys
from typing import Any


def get_kubectl_nodes() -> dict[str, Any]:
    """Query Kubernetes for node information."""
    try:
        result = subprocess.run(
            [
                "kubectl", "get", "nodes",
                "-o", "json",
                "--request-timeout=10s",
            ],
            capture_output=True,
            text=True,
            timeout=15,
            env={**os.environ, "KUBECONFIG": os.environ.get("KUBECONFIG", "~/.kube/config")},
        )
        if result.returncode != 0:
            return {}
        return json.loads(result.stdout)
    except (subprocess.TimeoutExpired, FileNotFoundError, json.JSONDecodeError):
        return {}


def build_inventory() -> dict[str, Any]:
    """Build the inventory from live Kubernetes data or fallback static config."""
    nodes_data = get_kubectl_nodes()
    inventory: dict[str, Any] = {
        "_meta": {
            "hostvars": {},
        },
        "all": {
            "children": ["k8s_cluster", "ungrouped"],
        },
        "k8s_cluster": {
            "children": ["k8s_controlplane", "k8s_workers"],
        },
        "k8s_controlplane": {"hosts": []},
        "k8s_workers": {"hosts": []},
    }

    if not nodes_data or "items" not in nodes_data:
        # Fallback to static inventory
        return fallback_inventory()

    for node in nodes_data.get("items", []):
        name = node.get("metadata", {}).get("name", "")
        addresses = node.get("status", {}).get("addresses", [])
        ip = ""
        for addr in addresses:
            if addr.get("type") == "InternalIP":
                ip = addr.get("address", "")
                break

        if not name or not ip:
            continue

        host_vars = {
            "ansible_host": ip,
            "ansible_user": os.environ.get("ANSIBLE_USER", "korab"),
            "ansible_python_interpreter": "/usr/bin/python3",
        }

        # Determine node role
        labels = node.get("metadata", {}).get("labels", {})
        is_controlplane = any(
            key in labels
            for key in [
                "node-role.kubernetes.io/control-plane",
                "node-role.kubernetes.io/master",
            ]
        )

        if is_controlplane:
            inventory["k8s_controlplane"]["hosts"].append(name)
            host_vars["node_role"] = "control-plane"
        else:
            inventory["k8s_workers"]["hosts"].append(name)
            host_vars["node_role"] = "worker"

        # GPU detection
        if "nvidia.com/gpu" in node.get("status", {}).get("capacity", {}):
            host_vars["gpu"] = "nvidia"

        # Add OS / kernel info
        node_info = node.get("status", {}).get("nodeInfo", {})
        host_vars["kubelet_version"] = node_info.get("kubeletVersion", "")
        host_vars["os_image"] = node_info.get("osImage", "")
        host_vars["kernel_version"] = node_info.get("kernelVersion", "")

        inventory["_meta"]["hostvars"][name] = host_vars

    return inventory


def fallback_inventory() -> dict[str, Any]:
    """Static fallback when kubectl is unavailable."""
    return {
        "_meta": {
            "hostvars": {
                "k8s-master": {
                    "ansible_host": os.environ.get("K8S_MASTER_IP", "192.168.0.83"),
                    "ansible_user": os.environ.get("ANSIBLE_USER", "mena"),
                    "node_role": "control-plane",
                    "gpu": ["amd", "intel"],
                },
                "k8s": {
                    "ansible_host": os.environ.get("K8S_IP", "192.168.0.107"),
                    "ansible_user": os.environ.get("ANSIBLE_USER", "kub"),
                    "node_role": "worker",
                    "gpu": ["amd"],
                },
                "k8s2": {
                    "ansible_host": os.environ.get("K8S2_IP", "192.168.0.159"),
                    "ansible_user": os.environ.get("ANSIBLE_USER", "kub"),
                    "node_role": "worker",
                    "gpu": ["intel"],
                },
            }
        },
        "all": {"children": ["k8s_cluster"]},
        "k8s_cluster": {"children": ["k8s_controlplane", "k8s_workers"]},
        "k8s_controlplane": {"hosts": ["k8s-master"]},
        "k8s_workers": {"hosts": ["k8s", "k8s2"]},
    }


def main() -> None:
    """Main entry point."""
    inventory = build_inventory()

    if len(sys.argv) > 1 and sys.argv[1] == "--list":
        print(json.dumps(inventory, indent=2))
    elif len(sys.argv) > 1 and sys.argv[1] == "--host":
        hostname = sys.argv[2] if len(sys.argv) > 2 else ""
        hostvars = inventory.get("_meta", {}).get("hostvars", {}).get(hostname, {})
        print(json.dumps(hostvars, indent=2))
    else:
        print(json.dumps(inventory, indent=2))


if __name__ == "__main__":
    main()
