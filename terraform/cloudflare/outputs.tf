output "tunnel_id" {
  value = cloudflare_tunnel.homelab.id
}

output "tunnel_token" {
  description = "Token to put in a sealed-secret for the cloudflared Deployment"
  value       = cloudflare_tunnel.homelab.tunnel_token
  sensitive   = true
}
