# 5. ArgoCD with app-of-apps + ApplicationSet

**Status:** Accepted
**Date:** 2026-05-16

## Context

Two real choices for GitOps on K8s: ArgoCD and Flux. Both work, both are CNCF graduated. Either would do.

## Decision

**ArgoCD**, configured with a single "root" `Application` that points at `kubernetes/argocd/apps/`, which contains two `ApplicationSet`s (one for infrastructure, one for apps). Each ApplicationSet auto-discovers folders and creates an `Application` per folder.

## Consequences

- Adding a new component = `mkdir` + commit + push. No editing of a central registry.
- Single root means there is exactly one imperative bootstrap step (`kubectl apply -f root-app.yaml`); everything else is reconciled.
- ArgoCD's UI is a real asset for debugging and for showing the project off. Flux is CLI-only.
- ArgoCD is heavier (4–5 pods) than Flux. Acceptable on a 3-VM cluster with 20+ GB of memory.
