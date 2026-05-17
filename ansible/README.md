# ansible/

Bootstraps the Terraform-provisioned VMs and installs k3s on them.

## Setup

```bash
cp inventory.example.yml inventory.yml
# fill in IPs from `cd ../terraform/proxmox && terraform output node_ips`
# or use `make inventory` from the repo root
```

## Run

```bash
ansible-playbook playbooks/bootstrap.yml
ansible-playbook playbooks/k3s.yml
```

After `k3s.yml`, your Mac has `~/.kube/homelab-config` pointing at the cluster:
```bash
export KUBECONFIG=~/.kube/homelab-config
kubectl get nodes   # → 3 Ready
```

## What each playbook does

| Playbook       | Does                                                                                              |
| -------------- | ------------------------------------------------------------------------------------------------- |
| `bootstrap.yml`| Apt upgrade; installs `qemu-guest-agent`, `tailscale`, base utilities; disables swap; sets sysctls. |
| `k3s.yml`      | Installs k3s server on `control_plane`, joins `workers`, fetches kubeconfig to your Mac.           |

## Why disable `traefik` and `servicelb`?

k3s ships its own ingress (Traefik) and an L2 loadbalancer (ServiceLB). We disable both because:
- ingress-nginx is the de-facto K8s ingress and what most Helm charts assume.
- MetalLB gives finer control over IP pools than ServiceLB and is widely used in homelabs.

This is captured in [ADR 0006](../docs/adr/0006-ingress-nginx-and-metallb-over-k3s-defaults.md).
