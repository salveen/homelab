# 4. Cloudflare Tunnel for public, Tailscale for private

**Status:** Accepted
**Date:** 2026-05-16

## Context

I'm on a residential ISP. No static IP, possible CGNAT, port-forwarding is fragile and exposes the home network. I have two kinds of services to expose:

1. **Public-facing web apps** — random people on the internet need to reach them.
2. **Private services** — Jellyfin, Grafana, ArgoCD UI, the Proxmox console. Only I (and people I share with) need to reach them.

## Decision

- **Cloudflare Tunnel** (`cloudflared` Deployment in-cluster) for category 1. The tunnel is outbound from the cluster; no inbound ports, IP changes irrelevant.
- **Tailscale** (operator in-cluster + `tailscaled` on the Jellyfin LXC and the Proxmox host) for category 2. WireGuard mesh, MagicDNS, works from anywhere.

## Consequences

- Two networking systems to learn instead of one. Each is well-documented and free at this scale.
- The home public IP is never exposed. Router configuration stays trivial.
- Jellyfin is intentionally **not** behind Cloudflare Tunnel — Cloudflare's free-plan ToS prohibits proxying significant video traffic. Streaming over Tailscale also gives a direct LAN path when I'm home.
- Sharing a private service with someone non-technical means inviting them to my tailnet (one-click in the Tailscale admin). Acceptable.
