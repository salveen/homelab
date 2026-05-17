#!/usr/bin/env bash
# Build the Ubuntu 24.04 cloud-init template VM. Run on the Proxmox host as root.
# Idempotent: re-run anytime to refresh the image.
set -euo pipefail

VMID="${VMID:-9000}"
NAME="${NAME:-ubuntu-2404-cloudinit}"
STORAGE="${STORAGE:-local-lvm}"
BRIDGE="${BRIDGE:-vmbr0}"
IMG_URL="${IMG_URL:-https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img}"
IMG_FILE="/tmp/$(basename "$IMG_URL")"

echo "→ Downloading Ubuntu 24.04 cloud image"
wget -nc -O "$IMG_FILE" "$IMG_URL"

echo "→ Installing libguestfs-tools (one-time, for virt-customize)"
apt-get update -qq
apt-get install -y libguestfs-tools

echo "→ Baking qemu-guest-agent into the image"
virt-customize -a "$IMG_FILE" --install qemu-guest-agent
virt-customize -a "$IMG_FILE" --run-command 'systemctl enable qemu-guest-agent'

# Destroy any existing template with the same VMID
if qm status "$VMID" >/dev/null 2>&1; then
  echo "→ Destroying existing VM $VMID"
  qm stop "$VMID" || true
  qm destroy "$VMID" --purge
fi

echo "→ Creating VM $VMID ($NAME)"
qm create "$VMID" \
  --name "$NAME" \
  --memory 2048 \
  --cores 2 \
  --cpu host \
  --net0 "virtio,bridge=$BRIDGE" \
  --ostype l26 \
  --agent enabled=1 \
  --serial0 socket --vga serial0

echo "→ Importing disk into $STORAGE"
qm importdisk "$VMID" "$IMG_FILE" "$STORAGE"

echo "→ Wiring up disk + cloud-init"
qm set "$VMID" --scsihw virtio-scsi-pci --scsi0 "$STORAGE:vm-$VMID-disk-0"
qm set "$VMID" --ide2 "$STORAGE:cloudinit"
qm set "$VMID" --boot c --bootdisk scsi0

echo "→ Converting to template"
qm template "$VMID"

echo "✓ Template VMID $VMID ready. Clone from Terraform now."
