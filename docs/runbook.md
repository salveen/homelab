# Runbook

What to do when things go wrong.

## A worker node dies / I need to reboot it

1. Drain it: `kubectl drain k3s-wk-1 --ignore-daemonsets --delete-emptydir-data`
2. Reboot in Proxmox UI or `qm reboot 111`.
3. Once Ready: `kubectl uncordon k3s-wk-1`.

Longhorn rebuilds any missing replicas automatically. Postgres failover happens before you notice.

## The control-plane node dies

You have no HA (intentional, v1). Cluster API is unavailable until cp-1 is back. Existing workloads keep serving traffic — kubelets are autonomous — but you can't deploy, scale, or change anything. Recovery:

1. Boot cp-1 in Proxmox. If the disk is gone, re-run `make apply` then `make k3s-install` — k3s on cp-1 will rejoin agents using the saved token.
2. If the node-token is lost, you have to reinstall the workers too. Tracked as a v2 improvement (move to embedded etcd HA across 3 control-plane nodes).

## Restore a Postgres cluster from snapshot

Per-cluster snapshots are taken by CloudNativePG nightly (see each app's `postgres.yaml`). To restore:

```bash
kubectl cnpg restore <new-cluster-name> --from <source-cluster> --backup <backup-name>
```

Or full-cluster point-in-time recovery using the Barman archive in B2 — see CloudNativePG docs.

## Cloudflare Tunnel is down (public apps unreachable)

```bash
kubectl -n cloudflared logs deploy/cloudflared --tail=200
```

Common causes:
- The token in the sealed-secret is stale (you re-created the tunnel in Terraform without re-sealing). Fix: re-run the `kubeseal` step in `terraform/cloudflare/README.md`.
- Cloudflare API hiccup. Check the dashboard.

## Tailscale auth expired on a node

```bash
ssh ubuntu@<node>
sudo tailscale up --auth-key=$NEW_PRE_AUTH_KEY
```

Or set `--ssh` and use ephemeral auth keys per node to avoid the re-auth dance.

## I broke ArgoCD itself

ArgoCD lives at `kubernetes/argocd/`. If ArgoCD itself becomes unhealthy, the bootstrap is recoverable:

```bash
make argocd-bootstrap   # idempotent helm upgrade
kubectl -n argocd rollout restart deployment
```

If the cluster is gone but you have the kubeconfig, re-running `make argocd-bootstrap` after a fresh `make k3s-install` re-reconciles everything from git.

## I want to start completely from scratch

```bash
make destroy           # tears down the VMs
ssh root@pve "bash -s" < proxmox/build-template.sh   # rebuild template
make apply             # new VMs
make k3s-install
make argocd-bootstrap
```

End-to-end: ~20 minutes on a decent box.
