resource "random_password" "tunnel_secret" {
  length  = 64
  special = false
}

resource "cloudflare_tunnel" "homelab" {
  account_id = var.cf_account_id
  name       = var.tunnel_name
  secret     = base64encode(random_password.tunnel_secret.result)
}

# One CNAME per public hostname → tunnel.
resource "cloudflare_record" "tunnel_cname" {
  for_each = var.public_hostnames

  zone_id = var.cf_zone_id
  name    = each.key
  type    = "CNAME"
  value   = "${cloudflare_tunnel.homelab.id}.cfargotunnel.com"
  proxied = true
  ttl     = 1 # 1 = automatic (required when proxied)
}

# Tunnel ingress config — which hostnames route to which in-cluster service.
resource "cloudflare_tunnel_config" "homelab" {
  account_id = var.cf_account_id
  tunnel_id  = cloudflare_tunnel.homelab.id

  config {
    dynamic "ingress_rule" {
      for_each = var.public_hostnames
      content {
        hostname = "${ingress_rule.key}.${var.domain}"
        service  = ingress_rule.value
      }
    }

    # Catch-all — required as the final rule.
    ingress_rule {
      service = "http_status:404"
    }
  }
}

output "tunnel_id" {
  value = cloudflare_tunnel.homelab.id
}

output "tunnel_token" {
  description = "Token to put in a sealed-secret for the cloudflared Deployment"
  value       = cloudflare_tunnel.homelab.tunnel_token
  sensitive   = true
}
