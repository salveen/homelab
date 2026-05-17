variable "pve_endpoint" {
  description = "Proxmox API endpoint, e.g. https://192.168.1.200:8006/"
  type        = string
}

variable "pve_api_token" {
  description = "Proxmox API token in the form user@realm!tokenid=uuid"
  type        = string
  sensitive   = true
}

variable "pve_insecure" {
  description = "Allow self-signed Proxmox TLS certs"
  type        = bool
  default     = true
}

variable "pve_ssh_username" {
  description = "SSH user the provider uses for some operations (e.g. file uploads)"
  type        = string
  default     = "root"
}

variable "pve_node" {
  description = "Proxmox node name (single-host cluster: usually 'pve')"
  type        = string
  default     = "pve"
}

variable "template_vmid" {
  description = "VMID of the Ubuntu 24.04 cloud-init template"
  type        = number
  default     = 9000
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key to inject into VMs"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "vm_user" {
  description = "Default user created via cloud-init"
  type        = string
  default     = "ubuntu"
}

variable "vm_datastore" {
  description = "Proxmox datastore for VM disks"
  type        = string
  default     = "local-lvm"
}

variable "vm_bridge" {
  description = "Linux bridge for VM network"
  type        = string
  default     = "vmbr0"
}

variable "nodes" {
  type = map(object({
    vmid   = number
    cores  = number
    memory = number
    disk   = number
    role   = string
    ip     = string   # new
  }))
  default = {
    "k3s-cp-1" = { vmid = 210, cores = 2, memory = 4096, disk = 40, role = "control-plane", ip = "192.168.1.210/24" }
    "k3s-wk-1" = { vmid = 211, cores = 4, memory = 8192, disk = 80, role = "worker",        ip = "192.168.1.211/24" }
    "k3s-wk-2" = { vmid = 212, cores = 4, memory = 8192, disk = 80, role = "worker",        ip = "192.168.1.212/24" }
  }
}
