# example-app

Reference layout for a web app. Copy this folder, rename, edit, push — the `apps` ApplicationSet picks it up automatically.

```
example-app/
├── deployment.yaml      # the app itself
├── service.yaml
├── ingress.yaml         # routes <name>.<domain> to the service (also referenced in CF tunnel config)
├── postgres.yaml        # CloudNativePG Cluster CR
└── README.md
```

Public exposure: add the hostname to `terraform/cloudflare/terraform.tfvars` under `public_hostnames`, then `terraform apply` in `terraform/cloudflare/`. The CNAME and the tunnel ingress rule appear immediately.

Private (tailnet-only) exposure instead: annotate the `Service` with `tailscale.com/expose: "true"` (no Ingress, no Cloudflare entry).
