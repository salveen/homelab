variable "cf_api_token" {
  description = "Cloudflare API token (Zone:DNS:Edit + Account:Cloudflare Tunnel:Edit)"
  type        = string
  sensitive   = true
}

variable "cf_account_id" {
  description = "Cloudflare account ID (Account home → right sidebar)"
  type        = string
}

variable "cf_zone_id" {
  description = "Cloudflare zone ID for your domain"
  type        = string
}

variable "domain" {
  description = "Apex domain, e.g. example.com"
  type        = string
}

variable "tunnel_name" {
  description = "Cloudflare Tunnel name"
  type        = string
  default     = "homelab"
}

variable "public_hostnames" {
  description = "Map of public hostname to the in-cluster service it routes to"
  type        = map(string)
  default = {
    # "app-a" = "http://ingress-nginx-controller.ingress-nginx.svc.cluster.local:80"
    # "app-b" = "http://ingress-nginx-controller.ingress-nginx.svc.cluster.local:80"
  }
}
