# terraform/proxmox

Provisions three Ubuntu 24.04 VMs on the Proxmox host by cloning the cloud-init template built in [`proxmox/build-template.sh`](../../proxmox/build-template.sh).

## Prerequisites

- The Ubuntu cloud-init template exists on the Proxmox host (default VMID `9000`).
- A Proxmox API token exists (`Datacenter → Permissions → API Tokens`). Default permissions for the homelab: a role with `VM.*`, `Datastore.AllocateSpace`, `Sys.Audit`, applied to `/`.
- An SSH keypair on the Mac (`ssh-keygen -t ed25519` if you don't have one).

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
$EDITOR terraform.tfvars

terraform init
terraform plan
terraform apply
```

Outputs `node_ips` map (`name → [v4, v4]`) and a convenience `ssh_commands` block.

## Notes

- Provider is [`bpg/proxmox`](https://registry.terraform.io/providers/bpg/proxmox/latest). The older `telmate/proxmox` provider is largely unmaintained — see [ADR 0003](../../docs/adr/0003-bpg-over-telmate-proxmox-provider.md).
- VM IPs are reported by `qemu-guest-agent`. If `node_ips` shows `null`, the agent isn't installed in the template — fix by running the bootstrap playbook once.
- Backend is `local` for now. Promote to S3/Terraform Cloud once you have remote state habits.
