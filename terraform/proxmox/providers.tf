terraform {
  required_version = ">= 1.6.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.66"
    }
  }

  # Start with a local backend. Swap for s3/terraform-cloud is possible.
  backend "local" {}
}

provider "proxmox" {
  endpoint  = var.pve_endpoint
  api_token = var.pve_api_token
  insecure  = var.pve_insecure

  # ssh {
  #   agent    = true
  #   username = var.pve_ssh_username
  # }
}
