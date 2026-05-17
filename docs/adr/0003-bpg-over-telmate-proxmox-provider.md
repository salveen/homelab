# 3. bpg/proxmox Terraform provider over telmate/proxmox

**Status:** Accepted
**Date:** 2026-05-16

## Context

Two Terraform providers can talk to Proxmox: the older `telmate/proxmox` and the newer `bpg/proxmox` (a.k.a. `proxmox-virtual-environment`). Most blog posts from 2021–2022 use telmate.

## Decision

Use **`bpg/proxmox`**.

## Consequences

- Active maintenance, faster issue turnaround, support for current Proxmox API versions.
- Cleaner cloud-init handling — first-class `initialization` block, no shelling out to `qm set --cicustom`.
- Slightly different resource names and schema; copy-pasting from old blog posts won't work, which is actually a feature (forces understanding).
- Smaller community-by-volume, but the docs are good enough that this hasn't bitten me.
