resource "proxmox_virtual_environment_vm" "node" {
  for_each = var.nodes

  name        = each.key
  vm_id       = each.value.vmid
  node_name   = var.pve_node
  description = "k3s ${each.value.role} — managed by Terraform"
  tags        = ["k3s", "terraform", each.value.role]

  clone {
    vm_id = var.template_vmid
    full  = true
  }

  agent {
    enabled = true
  }

  cpu {
    cores = each.value.cores
    type  = "host"
  }

  memory {
    dedicated = each.value.memory
  }

  disk {
    datastore_id = var.vm_datastore
    interface    = "scsi0"
    size         = each.value.disk
  }

  network_device {
    bridge = var.vm_bridge
    model  = "virtio"
  }

  operating_system {
    type = "l26"
  }

  initialization {
    datastore_id = var.vm_datastore

    ip_config {
      ipv4 {
        address = each.value.ip
        gateway = "192.168.1.1"   # your router IP
      }
    }

    user_account {
      username = var.vm_user
      keys     = [trimspace(file(pathexpand(var.ssh_public_key_path)))]
    }
  }

  lifecycle {
    ignore_changes = [
      # cloud-init re-renders on every apply otherwise
      initialization[0].user_account,
    ]
  }
}
