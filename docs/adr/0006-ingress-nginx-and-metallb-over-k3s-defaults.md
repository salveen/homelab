# 6. ingress-nginx + MetalLB over k3s's Traefik + ServiceLB

**Status:** Accepted
**Date:** 2026-05-16

## Context

k3s ships with Traefik (ingress) and ServiceLB (a simple L2 load-balancer using host ports). Both work. Most Helm charts in the wild assume ingress-nginx semantics (annotations, snippets, IngressClass naming).

## Decision

Disable k3s's bundled Traefik and ServiceLB at install time (`--disable=traefik --disable=servicelb`). Install **ingress-nginx** as the IngressClass and **MetalLB** as the LoadBalancer implementation.

## Consequences

- Helm charts work out of the box without rewriting annotations.
- MetalLB gives a predictable IP pool from my LAN (e.g. `192.168.1.240-250`); I can pin which IP a Service gets.
- Slightly more moving parts than the k3s defaults. The trade is worth it.
