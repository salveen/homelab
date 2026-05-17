# Run: `brew bundle` (from the repo root)
# Idempotent — re-run any time.

# Taps for formulae not in homebrew-core
tap "hashicorp/tap"          # terraform (BSL — pulled from core)
tap "terraform-linters/tap"  # tflint

# Core IaC / orchestration
brew "hashicorp/tap/terraform"
cask "terraform-linters/tap/tflint"  # distributed as a cask, not a formula
brew "terraform-docs"
brew "ansible"

# Kubernetes
brew "kubectl"
brew "helm"
brew "k9s"
brew "argocd"
brew "kubeconform"

# Cloudflare Tunnel client (handy for local testing)
brew "cloudflared"

# Secrets management
brew "age"
brew "sops"
brew "kubeseal"

# Quality-of-life
brew "pre-commit"
brew "jq"
brew "yq"
brew "gitleaks"
brew "yamllint"

# GUI
cask "tailscale-app"  # renamed from "tailscale" in homebrew-cask
