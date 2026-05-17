output "node_ips" {
  description = "Map of node name to IPv4 addresses (requires qemu-guest-agent)"
  value       = { for k, v in proxmox_virtual_environment_vm.node : k => v.ipv4_addresses }
}

output "cp1_ip" {
  description = "First IPv4 of the control-plane node, for kubeconfig munging"
  value       = try(proxmox_virtual_environment_vm.node["k3s-cp-1"].ipv4_addresses[1][0], null)
}

output "ssh_commands" {
  description = "Copy-pasteable SSH commands"
  value       = { for k, v in proxmox_virtual_environment_vm.node : k => "ssh ${var.vm_user}@${try(v.ipv4_addresses[1][0], "PENDING")}" }
}
