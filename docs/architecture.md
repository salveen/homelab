# Architecture

A deeper look than the top-level README.

## Layers

| Layer       | Lives in                              | Owned by                  |
| ----------- | ------------------------------------- | ------------------------- |
| Hardware    | Proxmox host                          | Manual / one-time         |
| Virtualization | Ubuntu VMs                         | Terraform (`terraform/proxmox/`) |
| Edge        | Cloudflare Tunnel + DNS               | Terraform (`terraform/cloudflare/`) |
| OS config   | apt, sysctls, tailscale, swap-off     | Ansible (`ansible/playbooks/bootstrap.yml`) |
| Cluster     | k3s                                   | Ansible (`ansible/playbooks/k3s.yml`) |
| Cluster services | ingress, storage, DBs, monitoring | ArgoCD (`kubernetes/infrastructure/`) |
| Applications | Web apps + per-app Postgres          | ArgoCD (`kubernetes/apps/`) |

Each layer is reproducible from a fresh machine — that's the test.

## Network paths

### Public web app request
```
user browser
  → cloudflare edge (anycast)
  → outbound-initiated tunnel to cloudflared pod (no inbound ports)
  → cloudflared → ingress-nginx (cluster-internal Service)
  → app Pod
```

The home router never sees an inbound connection. The public IP is irrelevant.

### Me reaching Jellyfin from abroad
```
my laptop (tailscale)
  → tailscale relay OR direct WireGuard peer
  → tailscaled inside the Jellyfin LXC
  → jellyfin :8096
```

When I'm physically at home, Tailscale uses NAT traversal to peer directly over the LAN — gigabit, zero relay hops.

### Me managing Proxmox
Same path as Jellyfin, but the tailscaled daemon runs on the Proxmox host itself.

## Storage

- Longhorn replicates each PVC across all 3 nodes by default. Losing one node still leaves 2 replicas — the workload keeps running.
- Postgres clusters provisioned by CloudNativePG are `replicas: 3` and use Longhorn-backed PVCs. Failover is automatic; recovery from a node loss is sub-minute.
- Backups: `Cluster.spec.backup.barmanObjectStore` points at a Backblaze B2 bucket. (Not configured in v1 — see `runbook.md`.)

## Secrets

- `terraform.tfvars` is `.gitignore`-d. The CI workflow injects values from GitHub secrets.
- Kubernetes Secrets are committed to git **only** through `sealed-secrets` — the sealing key lives in-cluster and can decrypt them, no one else can.
- An alternative considered was `sops` + `age` (encrypted in git, decrypted by Helm/Kustomize at apply-time). Rejected in favour of sealed-secrets because GitOps reconciliation should be able to apply a Secret without holding a private key. See ADR 0007 if you write one.

## Why three VMs and not just LXCs

K8s on LXC is possible but pulls you into kernel-sharing surprises (apparmor, cgroups v2, kubelet not loving unprivileged containers). VMs give clean isolation, snapshottable state, and let Terraform manage them exactly like real cloud instances — better skills transfer.
