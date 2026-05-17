# Hands-on walkthrough

Conventions used below:
- **Where you run things** is called out at the start of every block: *(on your Mac)*, *(on the Proxmox host)*, *(inside a VM)*.
- The Proxmox host can be reached two ways: SSH (`ssh root@pve.lan`) or the web UI's **Node shell** (click your node name in the left sidebar → `>_ Shell` button). Both are identical bash sessions on the host. They're **not** the same as a VM's console (which is the inside of a guest VM and doesn't exist yet).
- `pve.lan` throughout means "your Proxmox host" — replace with its IP or DNS name.

---

## Phase 0 — Local tooling on the Mac

*(on your Mac)*

```bash
# Install Homebrew if you don't have it
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# From the repo root
brew bundle
```

Verify the four tools you'll touch most:

```bash
terraform -version
kubectl version --client
helm version
argocd version --client
```

Generate an SSH keypair if you don't already have one — it'll be injected into every VM you create:

```bash
ls ~/.ssh/id_ed25519.pub 2>/dev/null || ssh-keygen -t ed25519 -C "$(whoami)@$(hostname)"
```

**Done when:** all four version commands print something and `~/.ssh/id_ed25519.pub` exists.

---

## Phase 1 — Proxmox prep

You'll do this once. After it's done, everything else is Terraform/Ansible/Git.

### 1.1 Create the Terraform user + API token (in the Proxmox UI)

*(in a browser, on the Proxmox web UI)*

**Create the user.** `Datacenter → Users → Add`
- Username: `terraform`
- Realm: `Proxmox VE authentication server (pve)` ← **not** PAM/Linux
- Set a strong password (you won't actually use it — the token will do the auth)
- Enable: ✓

You now have a user `terraform@pve`.

**Create the API token.** `Datacenter → Permissions → API Tokens → Add`
- User: `terraform@pve`
- Token ID: `main`
- **Privilege Separation: UNCHECK this box.** With it checked, the token has zero permissions even though the user does. Unchecking means "the token inherits the user's permissions."
- Expire: leave blank

A popup shows the **token secret value** — a UUID. The full credential string you'll put in `terraform.tfvars` later looks like:

```
terraform@pve!main=12345678-90ab-cdef-1234-567890abcdef
```

(Format: `user@realm!tokenid=secret`.)

**Grant permissions.** `Datacenter → Permissions → Add → User Permission`

Add two rows on path `/`:

| Path | User | Role |
|------|------|------|
| `/`  | `terraform@pve` | `PVEVMAdmin` |
| `/`  | `terraform@pve` | `PVEDatastoreUser` |

(Propagate stays checked.)

**Homelab shortcut:** if RBAC errors annoy you, give `PVEAdmin` on `/` instead of those two — broader, simpler, fine for a homelab. Even faster: skip the dedicated user entirely and make a token directly on `root@pam` with Privilege Separation off. You can tighten this later in 5 minutes.

### 1.2 Verify the token works

*(on your Mac terminal — important, not zsh-quoted)*

```bash
curl -k -H 'Authorization: PVEAPIToken=terraform@pve!main=THE-UUID' \
  https://pve.lan:8006/api2/json/version
```

**Note the single quotes** around the `Authorization:` header value. The `!` in the token string is a zsh history-expansion character — double quotes will make zsh try to interpret `!main` and fail with `zsh: event not found`. Single quotes pass the string through literally.

Replace `THE-UUID` with your token secret. Expected output:

```json
{"data":{"version":"9.x.x","release":"...","repoid":"..."}}
```

**Done when:** the JSON above prints. A `401 permission denied` means you forgot to uncheck Privilege Separation on the token.

### 1.3 Build the Ubuntu 24.04 cloud-init template

*(on the Proxmox host — either SSH from your Mac or open Node → Shell in the UI)*

The "template VM" is a VM you never start; it exists only to be cloned by Terraform later. Three VMs is much easier to build by cloning an already-configured image than by installing Ubuntu from scratch three times.

```bash
# Download the Ubuntu 24.04 cloud image (note the LEADING SLASH on /tmp).
cd /tmp
wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img

# Install the tools that let us edit the image without booting it.
apt-get update -qq
apt-get install -y libguestfs-tools

# Bake qemu-guest-agent into the image. Without this, Terraform can't read
# back the VM's IP after clone, which makes everything painful.
virt-customize -a /tmp/noble-server-cloudimg-amd64.img --install qemu-guest-agent
virt-customize -a /tmp/noble-server-cloudimg-amd64.img \
  --run-command 'systemctl enable qemu-guest-agent'

# Create the empty VM shell. 9000 is convention for templates — keeps them
# visually separated from real VMs (which usually start at 100).
qm create 9000 \
  --name ubuntu-2404-cloudinit \
  --memory 2048 \
  --cores 2 \
  --cpu host \
  --net0 virtio,bridge=vmbr0 \
  --ostype l26 \
  --agent enabled=1 \
  --serial0 socket --vga serial0

# Import the cloud image as a disk attached to VM 9000.
qm importdisk 9000 /tmp/noble-server-cloudimg-amd64.img local-lvm

# Wire it up: scsi controller, the imported disk on scsi0, a cloud-init
# drive (where Terraform writes hostname/IP/SSH-key into), and boot order.
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --boot c --bootdisk scsi0

# Freeze it as a read-only template.
qm template 9000
```

**If `vmbr0` doesn't exist:** run `ip link show | grep vmbr` to see what bridge names you have. Substitute whichever one is your LAN bridge.
**If `local-lvm` doesn't exist:** run `pvesm status` and use whichever storage shows up. Some installs only have `local` (file-based).

**Done when:** in the Proxmox UI sidebar, VM 9000 appears with a "stack of disks" icon (the template icon, not the regular VM icon).

---

## Phase 2 — Terraform: clone the three VMs

*(on your Mac)*

```bash
cd ~/code/homelab/terraform/proxmox
cp terraform.tfvars.example terraform.tfvars
$EDITOR terraform.tfvars
```

Fill in the four required values:

```hcl
pve_endpoint        = "https://pve.lan:8006/"
pve_api_token       = "terraform@pve!main=YOUR-UUID-HERE"
pve_node            = "pve"           # your node name from the Proxmox UI sidebar
template_vmid       = 9000
ssh_public_key_path = "~/.ssh/id_ed25519.pub"
```

Then:

```bash
terraform init     # downloads the bpg/proxmox provider
terraform plan     # shows you what will be created (read this!)
terraform apply    # type `yes` when prompted
```

Apply takes ~60 seconds. When it finishes, ask for the IPs:

```bash
terraform output node_ips
terraform output ssh_commands
```

Test SSH into each:

```bash
ssh ubuntu@<ip-of-cp-1>
```

**Done when:** you can SSH into all three VMs as the `ubuntu` user using your existing key (no password prompt, no extra setup).

**If `terraform plan` errors with `failed to authenticate`:** double-check the token string in `terraform.tfvars` matches the format `user@realm!tokenid=uuid`. The `!` does not need escaping inside a `.tfvars` file (it's not a shell context).

**If `terraform apply` succeeds but `node_ips` is empty or null:** the VMs are up but `qemu-guest-agent` didn't start. SSH in once and run `systemctl status qemu-guest-agent`; if it's masked or failed, your template image didn't have it baked correctly — rebuild the template (Phase 1.3) and re-clone.

---

## Phase 3 — Ansible: install k3s

*(on your Mac, from the repo root)*

```bash
# Build the inventory from terraform output
make inventory   # writes ansible/inventory.yml directly

# OR: hand-edit ansible/inventory.example.yml with your IPs and save as inventory.yml.
```

Run the two playbooks:

```bash
make bootstrap     # apt upgrade, qemu-guest-agent, tailscale install, sysctls
make k3s-install   # k3s server on cp-1, agents on workers, kubeconfig pulled to Mac
```

Verify:

```bash
export KUBECONFIG=~/.kube/homelab-config
kubectl get nodes
```

**Done when:** `kubectl get nodes` shows three nodes, all `Ready`, with the right roles (one `control-plane`, two `<none>`).

**If `Ready` takes more than 60 seconds:** flannel (the default k3s CNI) is fetching images. `kubectl get pods -A` shows what's pending; wait.

**If `Permission denied (publickey)` during the Ansible run:** the playbook is using `ansible_user: ubuntu` and `~/.ssh/id_ed25519`. Make sure those match what cloud-init put in the VMs (Phase 2).

---

## Phase 4 — ArgoCD bootstrap

*(on your Mac)*

This is the one and only time you do an imperative install. After this, every cluster change goes through git.

```bash
make argocd-bootstrap
```

That target does, in order: add the Argo Helm repo, create the `argocd` namespace, `helm upgrade --install` ArgoCD with `kubernetes/bootstrap/argocd-values.yaml`, and `kubectl apply` the root `Application` from `kubernetes/argocd/root-app.yaml`.

**Before you run it**, edit `kubernetes/argocd/root-app.yaml` and the two ApplicationSets in `kubernetes/argocd/apps/` — change `REPLACE_ME` to your actual GitHub repo URL.

Open the UI:

```bash
make argocd-password         # prints the initial admin password
make argocd-port-forward     # then visit https://localhost:8080 in your browser
```

Login: `admin` / *(the password from the previous command)*.

**Done when:** the ArgoCD web UI shows the `root` Application and the two ApplicationSets (`infrastructure`, `apps`) all in "Synced + Healthy" state. Initially the ApplicationSets won't have any children — that's expected, you haven't filled in `kubernetes/infrastructure/*` yet.

---

## Phase 5 — Infrastructure layer (one component at a time)

*(in your editor + `git push` — never touch the cluster directly)*

For each of the nine infrastructure components, the flow is identical:

1. Open the matching folder under `kubernetes/infrastructure/<name>/`.
2. Add the Helm `Application` manifest or the raw manifests (see `ingress-nginx/helmrelease.yaml` and `cloudflared/deployment.yaml` for two worked examples).
3. Commit, push.
4. Watch ArgoCD pick it up automatically (ApplicationSets discover the folder on the next 3-minute sync, or click "Refresh" in the UI to force it).
5. Don't move to the next one until the current one is "Synced + Healthy".

Recommended order (each depends on the ones above it):

1. **metallb** — gives `LoadBalancer` services a real LAN IP. Configure an `IPAddressPool` from your home network (e.g. `192.168.1.240-192.168.1.250`).
2. **ingress-nginx** — HTTP routing. Worked example already in the repo at `kubernetes/infrastructure/ingress-nginx/helmrelease.yaml`.
3. **cert-manager** — TLS via Cloudflare DNS-01. Needs a Cloudflare API token (DNS:Edit on your zone) stored as a secret.
4. **longhorn** — distributed block storage across the 3 nodes. Set it as the default StorageClass.
5. **sealed-secrets** — lets you commit encrypted Secrets to git. Install before anything that needs a Secret.
6. **cloudnative-pg** — Postgres operator. After install, you provision one Cluster CR per app.
7. **kube-prometheus-stack** — Prometheus + Grafana + Alertmanager. Expose Grafana via Tailscale only.
8. **cloudflared** — the public tunnel pod. Worked example at `kubernetes/infrastructure/cloudflared/`. Requires Phase 5b below.
9. **tailscale-operator** — lets you `tailscale.com/expose: "true"` annotate any Service.

### 5b — Cloudflare side (one-time Terraform run)

*(on your Mac)*

In your Cloudflare dashboard:
- Create an API token with `Zone:DNS:Edit` and `Account:Cloudflare Tunnel:Edit` scopes.
- Grab the Account ID (right sidebar of the account home) and Zone ID (right sidebar of your domain).

Then:

```bash
cd ~/code/homelab/terraform/cloudflare
cp terraform.tfvars.example terraform.tfvars
$EDITOR terraform.tfvars        # fill in the tokens/IDs and domain
terraform init && terraform apply

# Seal the tunnel token so cloudflared can read it.
terraform output -raw tunnel_token | \
  kubeseal --raw --namespace cloudflared --name cloudflared-token --from-file=/dev/stdin
# paste the output into kubernetes/infrastructure/cloudflared/sealed-token.yaml
```

Commit + push. The `cloudflared` Deployment will pick up the SealedSecret and the tunnel will come up.

**Done when:** all nine ArgoCD child applications are green, the `cloudflared` logs show `Registered tunnel connection`, and Grafana opens at `grafana.tail-xxxx.ts.net`.

---

## Phase 6 — Your apps + Jellyfin + Proxmox over Tailscale

### 6a — Tailscale on the Jellyfin LXC

*(SSH into the LXC, or open its console from Proxmox UI)*

```bash
apt update && apt install -y tailscale
tailscale up
# Visit the URL it prints in a browser, authenticate to your tailnet.
```

That's it. Jellyfin is now reachable from anywhere as `jellyfin.tail-xxxx.ts.net:8096`.

### 6b — Tailscale on the Proxmox host

*(on the Proxmox host — SSH or Node shell)*

```bash
apt update && apt install -y tailscale
tailscale up --advertise-routes=192.168.1.0/24   # replace with your LAN CIDR
```

Approve the subnet route in your Tailscale admin console. Now from anywhere on your tailnet you can reach:
- `https://pve.tail-xxxx.ts.net:8006` — the Proxmox UI
- `192.168.1.x` IPs directly — printers, router admin, the Jellyfin LXC, anything on your LAN

Never expose the Proxmox UI publicly. Tailscale-only is the right answer.

### 6c — Your first app

Copy `kubernetes/apps/example-app/` to `kubernetes/apps/<name>/` and fill in:

```
<name>/
├── deployment.yaml        # pulls ghcr.io/you/<name>:<tag>
├── service.yaml
├── ingress.yaml           # host: <name>.<your-domain>
└── postgres.yaml          # CloudNativePG Cluster CR if the app needs a DB
```

For each new public hostname, also add it to `terraform/cloudflare/terraform.tfvars` under `public_hostnames`, then `terraform apply` in `terraform/cloudflare/`. That creates the CNAME and the tunnel ingress rule in one shot.

**Done when:** you can hit `https://<app>.<your-domain>` from your phone on cellular and see your app.

---

## What "done" looks like for the whole project

- `kubectl get nodes` → 3 Ready
- `argocd app list` → all green
- `https://<some-app>.<your-domain>` works from cellular data with no port forwarding
- `https://jellyfin.tail-xxxx.ts.net:8096` works from a hotel WiFi
- `https://pve.tail-xxxx.ts.net:8006` works from the same hotel WiFi
- `terraform destroy && terraform apply && make k3s-install && make argocd-bootstrap` rebuilds the entire cluster in under 20 minutes from a single command sequence
- The repo's `main` branch builds green on every push (lint + terraform fmt + kubeconform)
- Renovate has opened at least one update PR