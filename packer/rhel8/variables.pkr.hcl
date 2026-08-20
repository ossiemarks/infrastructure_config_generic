# ---------------------------------------------------------------------------
# Proxmox connection — fill these in once your Proxmox VE host is up.
# Store the resulting credentials in LastPass.
# ---------------------------------------------------------------------------
variable "proxmox_url" {
  type        = string
  description = "Proxmox API URL, e.g. https://proxmox.example.com:8006/api2/json"
}

variable "proxmox_username" {
  type        = string
  description = "API token ID, format: user@realm!tokenid, e.g. packer@pve!packer"
}

variable "proxmox_token" {
  type        = string
  sensitive   = true
  description = "API token secret"
}

variable "proxmox_node" {
  type        = string
  description = "Proxmox node name to build on"
}

variable "proxmox_insecure_skip_tls_verify" {
  type    = bool
  default = true
}

variable "proxmox_storage_pool" {
  type        = string
  description = "Storage pool for the VM disk and cloud-init drive (e.g. local-lvm)"
}

variable "proxmox_vm_pool" {
  type    = string
  default = ""
}

# ---------------------------------------------------------------------------
# Guest identity
# ---------------------------------------------------------------------------
variable "vm_id" {
  type        = number
  description = "Proxmox VM ID for the build VM / resulting template"
}

variable "vm_name" {
  type    = string
  default = "rhel8-base"
}

variable "template_description" {
  type    = string
  default = "RHEL 8 base image"
}

variable "build_version" {
  type        = string
  description = "Build tag appended to the VM/template name, e.g. 2026-08-20 or 1.0.0"
}

# ---------------------------------------------------------------------------
# Install media — RHEL requires a Red Hat account to download (no stable
# public URL like CentOS/Fedora mirrors), so this must already be uploaded
# to Proxmox storage before running `packer build`. See README.md.
# ---------------------------------------------------------------------------
variable "rhel_iso_file" {
  type        = string
  description = "Proxmox storage path to the RHEL 8 binary DVD ISO, e.g. local:iso/rhel-8.10-x86_64-dvd.iso"
}

# ---------------------------------------------------------------------------
# Guest credentials — build-time only. See scripts/cleanup.sh: this key is
# removed from authorized_keys and SSH password auth stays disabled before
# the template is sealed. Register a real login/SSH key per deployed clone.
# ---------------------------------------------------------------------------
variable "ssh_private_key_file" {
  type        = string
  default     = "~/.ssh/packer_rhel8_ed25519"
  description = "Private half of a dedicated build keypair. Generate with: ssh-keygen -t ed25519 -f ~/.ssh/packer_rhel8_ed25519 -N ''"
}

variable "ssh_public_key_file" {
  type        = string
  default     = "~/.ssh/packer_rhel8_ed25519.pub"
  description = "Public half of the same build keypair"
}

# ---------------------------------------------------------------------------
# Guest hardware
# ---------------------------------------------------------------------------
variable "vm_memory" {
  type    = number
  default = 4096
}

variable "vm_cores" {
  type    = number
  default = 2
}

variable "vm_disk_size" {
  type    = string
  default = "30G"
}

variable "network_bridge" {
  type    = string
  default = "vmbr0"
}

variable "boot_wait" {
  type    = string
  default = "10s"
}

# ---------------------------------------------------------------------------
# Locale
# ---------------------------------------------------------------------------
variable "locale" {
  type    = string
  default = "en_US.UTF-8"
}

variable "keyboard" {
  type    = string
  default = "us"
}

variable "timezone" {
  type    = string
  default = "UTC"
}
