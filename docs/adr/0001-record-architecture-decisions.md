# 1. Record architecture decisions

**Status:** Accepted
**Date:** 2026-05-16

## Context

This repo will accumulate dozens of small choices — distros, providers, ingress controllers, secrets handling — each defensible in isolation but only making sense as a set. A future me (or a recruiter) reading the repo six months from now should be able to reconstruct *why* without having to git-blame.

## Decision

Each non-obvious decision gets an ADR in this folder, numbered sequentially, using the [Nygard format](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions): Context, Decision, Consequences.

## Consequences

- Adding a new ADR is one file. Friction is low; the bar to writing one stays low.
- Superseded ADRs stay in the repo with a `Superseded by 00NN` line at the top — the history is part of the value.
