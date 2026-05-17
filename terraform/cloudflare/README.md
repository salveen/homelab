# terraform/cloudflare

Manages the Cloudflare Tunnel and its public DNS records as code. After `terraform apply`, the `tunnel_token` output goes into a sealed-secret consumed by the in-cluster `cloudflared` Deployment.

## Workflow

```bash
cp terraform.tfvars.example terraform.tfvars
$EDITOR terraform.tfvars
terraform init
terraform apply
terraform output -raw tunnel_token | kubeseal --raw --namespace cloudflared --name cloudflared-token
# paste the sealed value into kubernetes/infrastructure/cloudflared/sealed-token.yaml
```

## Adding a new public app

Append to `public_hostnames` in `terraform.tfvars`, `terraform apply`, then add the corresponding `Ingress` in the app's Kubernetes manifest. That's it — DNS, tunnel routing, and ingress all flow from one PR.
