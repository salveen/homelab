# 2. k3s over RKE2, kubeadm, or Talos

**Status:** Accepted
**Date:** 2026-05-16

## Context

I want to learn Kubernetes properly and end up with a cluster that actually runs workloads — not just a clever install. The realistic options on three Ubuntu VMs:

- **kubeadm**: vanilla upstream. Most "real". Maximum complexity (etcd, kubelet, certs, CNI all hand-managed). High learning value but slow time-to-first-app.
- **k3s**: single binary, batteries-included (sqlite or etcd, flannel, traefik, servicelb). Installs in 30 seconds. Used in production at real scale (Rancher fleet, edge deployments).
- **RKE2**: Rancher's CNCF-conformant, hardened distro. Heavier than k3s, lighter than kubeadm.
- **Talos**: API-managed immutable OS. Very modern. Breaks the "SSH into the VM" mental model that a homelab newcomer benefits from.

## Decision

**k3s**, with traefik and servicelb disabled in favour of ingress-nginx + MetalLB.

## Consequences

- Fast time-to-first-app, so I actually get to ArgoCD/Postgres/apps quickly instead of spending three weekends configuring etcd.
- The k3s install is still real Kubernetes — every kubectl, every manifest, every Helm chart works identically. Skills transfer.
- I lose the "I configured etcd from scratch" talking point. Mitigated by writing about *why* I chose k3s instead of demonstrating low-level mastery.
- Single control-plane node by default. Documented as a known limitation; HA upgrade path is well-trodden (k3s + embedded etcd across 3 nodes).
