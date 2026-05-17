# kubernetes/bootstrap/

One-time imperative install of ArgoCD. After this runs, every subsequent change to the cluster goes through git.

```bash
make argocd-bootstrap
make argocd-password           # admin/<printed value>
make argocd-port-forward       # then visit https://localhost:8080
```

`argocd-values.yaml` only configures the install itself. Day-2 config (RBAC, repo creds, projects) lives under `../argocd/`.
