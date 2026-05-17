# proxmox/

One-time host-level scripts. Run these directly on the Proxmox host as `root`.

## `build-template.sh`

Downloads the Ubuntu 24.04 cloud image, bakes in `qemu-guest-agent`, and creates Proxmox template VM `9000` ready for Terraform to clone.

Run remotely from your Mac:
```bash
ssh root@pve "bash -s" < proxmox/build-template.sh
```

Environment overrides: `VMID`, `NAME`, `STORAGE`, `BRIDGE`, `IMG_URL`.
