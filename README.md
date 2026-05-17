# Homelab

[![Terraform](https://img.shields.io/badge/Terraform-1.6+-7B42BC?logo=terraform&logoColor=white)](./terraform)
[![k3s](https://img.shields.io/badge/k3s-v1.30-FFC61C?logo=kubernetes&logoColor=white)](./kubernetes)
[![ArgoCD](https://img.shields.io/badge/ArgoCD-GitOps-EF7B4D?logo=argo&logoColor=white)](./kubernetes/argocd)
[![Renovate](https://img.shields.io/badge/Renovate-enabled-blue?logo=renovatebot)](./renovate.json)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](./LICENSE)

A fully GitOps-driven homelab running on a single Proxmox host. Three Ubuntu VMs are provisioned by Terraform, joined into a k3s cluster by Ansible, and from that point on every workload — ingress, storage, databases, monitoring, the Cloudflare Tunnel, the Tailscale operator, and the applications themselves — is reconciled from this repository by ArgoCD.

## Architecture

```mermaid
flowchart TB
    subgraph internet[" "]
        direction LR
        users["Public users<br/>(anywhere on Earth)"]
        me["Me<br/>(laptop / phone)"]
    end

    cf["Cloudflare Edge"]
    tailnet["Tailscale<br/>tailnet"]

    subgraph proxmox["Proxmox host"]
        direction TB
        subgraph cluster["k3s cluster (1 cp + 2 workers)"]
            cloudflared["cloudflared<br/>(outbound tunnel)"]
            ingress["ingress-nginx"]
            ts_op["tailscale-operator"]
            apps["Web apps<br/>+ CloudNativePG"]
            longhorn["Longhorn<br/>(storage)"]
            prom["kube-prometheus-stack"]
            argo["ArgoCD"]
        end
        jellyfin["LXC: Jellyfin<br/>+ tailscaled"]
    end

    repo["This GitHub repo"]

    users -->|HTTPS| cf
    cf -.outbound tunnel.- cloudflared
    cloudflared --> ingress --> apps
    me --> tailnet
    tailnet -.-> jellyfin
    tailnet -.-> ts_op
    ts_op -.-> prom
    ts_op -.-> argo
    repo -->|webhook / poll| argo
    argo -->|reconcile| cluster
```

The split is deliberate. **Cloudflare Tunnel** carries traffic for anything I want the public to reach, with no port forwarding and no static IP required. **Tailscale** carries traffic for anything only I (or invited people) should reach: Jellyfin, Grafana, the ArgoCD UI, the Proxmox admin console.


To reproduce from scratch, follow the instructions in [SETUP.md](./SETUP.md).

## License

MIT — see [LICENSE](./LICENSE).
