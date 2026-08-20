variable "proxmox_endpoint" {
  type        = string
  description = "Proxmox API endpoint, e.g. https://proxmox.example.com:8006/ (no /api2/json suffix)"
}

variable "proxmox_api_token" {
  type        = string
  sensitive   = true
  description = "API token in the form user@realm!tokenid=secret"
}

variable "proxmox_ssh_username" {
  type        = string
  default     = "root"
  description = "SSH user the provider uses for node-level operations (file uploads, some VM actions)"
}

variable "proxmox_insecure" {
  type    = bool
  default = true
}

variable "node_name" {
  type        = string
  description = "Proxmox node to create the test VM on"
}

variable "template_vm_id" {
  type        = number
  description = "VM ID of the Windows 11 template built by Packer (matches vm_id in packer/windows11/pkrvars.hcl.example)"
}

variable "vm_id" {
  type        = number
  description = "VM ID for the new test VM cloned from the template"
}

variable "vm_name" {
  type    = string
  default = "win11-test"
}

variable "datastore_id" {
  type        = string
  default     = "local-lvm"
  description = "Datastore for the cloned VM's disk"
}

variable "disk_size" {
  type        = number
  default     = 80
  description = "Disk size in GB. Must be >= the template's disk size when growing; shrinking is not supported."
}

variable "cpu_cores" {
  type    = number
  default = 4
}

variable "memory_mb" {
  type    = number
  default = 8192
}

variable "network_bridge" {
  type    = string
  default = "vmbr0"
}
