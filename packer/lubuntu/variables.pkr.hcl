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

variable "proxmox_iso_storage_pool" {
  type        = string
  default     = "local"
  description = "Storage pool Proxmox downloads the Ubuntu ISO into (e.g. local)"
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
  default = "lubuntu-base"
}

variable "template_description" {
  type    = string
  default = "Lubuntu (LXQt on Ubuntu Server 26.04 LTS) base image"
}

variable "build_version" {
  type        = string
  description = "Build tag appended to the VM/template name, e.g. 2026-08-20 or 1.0.0"
}

# ---------------------------------------------------------------------------
# Install media — publicly downloadable, no pre-upload needed. Verify
# against https://releases.ubuntu.com/26.04/ if this has moved to a newer
# point release since this was written.
# ---------------------------------------------------------------------------
variable "ubuntu_iso_url" {
  type    = string
  default = "https://releases.ubuntu.com/26.04/ubuntu-26.04-live-server-amd64.iso"
}

variable "ubuntu_iso_checksum" {
  type    = string
  default = "file:https://releases.ubuntu.com/26.04/SHA256SUMS"
}

# ---------------------------------------------------------------------------
# Guest credentials
# ---------------------------------------------------------------------------
variable "ssh_private_key_file" {
  type        = string
  default     = "~/.ssh/packer_lubuntu_ed25519"
  description = "Private half of a dedicated build keypair, used for root access only during the build. Generate with: ssh-keygen -t ed25519 -f ~/.ssh/packer_lubuntu_ed25519 -N ''"
}

variable "ssh_public_key_file" {
  type        = string
  default     = "~/.ssh/packer_lubuntu_ed25519.pub"
  description = "Public half of the same build keypair"
}

variable "local_username" {
  type        = string
  default     = "lubuntu"
  description = "The real interactive desktop-login user created on the machine (sudo-enabled). This is the account you actually log into after deployment - distinct from the build-time root SSH access."
}

variable "local_password_hash" {
  type        = string
  sensitive   = true
  description = "A crypt(3) SHA-512 password hash for local_username. Generate with real OpenSSL (macOS's built-in openssl is LibreSSL and lacks -6): $(brew --prefix openssl@3)/bin/openssl passwd -6 'your password here'. Plaintext is never accepted here - Subiquity's autoinstall schema requires a pre-hashed value."
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
  type        = string
  default     = "40G"
  description = "Larger than a headless server default - lubuntu-desktop plus apps needs meaningfully more room than a minimal install"
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

variable "keyboard_layout" {
  type    = string
  default = "us"
}

variable "timezone" {
  type    = string
  default = "UTC"
}
