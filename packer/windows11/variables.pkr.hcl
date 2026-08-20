# ---------------------------------------------------------------------------
# Proxmox connection — fill these in once your Proxmox VE host is up.
# Create a Packer-specific API token in Proxmox: Datacenter > Permissions > API Tokens.
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
  type        = bool
  default     = true
  description = "Skip TLS verification — set false once you have a trusted cert on the Proxmox API"
}

variable "proxmox_storage_pool" {
  type        = string
  description = "Storage pool for the VM disk, EFI disk and TPM state (e.g. local-lvm)"
}

variable "proxmox_iso_storage_pool" {
  type        = string
  description = "Storage pool Packer can upload the generated autounattend CD to (e.g. local)"
}

variable "proxmox_vm_pool" {
  type        = string
  default     = ""
  description = "Optional Proxmox resource pool to assign the VM/template to"
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
  default = "win11-base"
}

variable "template_description" {
  type    = string
  default = "Windows 11 base image"
}

variable "build_version" {
  type        = string
  description = "Build tag appended to the VM/template name, e.g. 2026-08-20 or 1.0.0"
}

# ---------------------------------------------------------------------------
# Install media — must already be uploaded to Proxmox storage before running
# `packer build`. See README.md for where to get these.
# ---------------------------------------------------------------------------
variable "windows_iso_file" {
  type        = string
  description = "Proxmox storage path to the Windows 11 ISO, e.g. local:iso/Win11_25H2_English_x64.iso"
}

variable "virtio_iso_file" {
  type        = string
  description = "Proxmox storage path to the VirtIO drivers ISO, e.g. local:iso/virtio-win.iso"
}

variable "windows_image_index" {
  type        = number
  default     = 6
  description = "WIM image index of the target edition inside install.wim. Verify with `dism /Get-WimInfo /WimFile:install.wim` on your specific ISO — index 6 is typically Windows 11 Pro on a multi-edition consumer ISO, but this varies by ISO."
}

variable "product_key" {
  type        = string
  default     = "W269N-WFGWX-YVC9B-4J6C9-T83GX"
  description = "Windows Setup product key. Defaults to Microsoft's public generic (KMS client setup) key for Windows 11 Pro, which only selects the edition during install — it does NOT license the machine. Replace with your real Volume License / MAK / retail key, or leave the default and activate separately after deployment."
}

# ---------------------------------------------------------------------------
# Guest credentials
# ---------------------------------------------------------------------------
variable "admin_password" {
  type        = string
  sensitive   = true
  description = "Administrator password set during install and used by Packer's WinRM connection. Supply via a gitignored *.auto.pkrvars.hcl or PKR_VAR_admin_password env var — never commit it. Store it in LastPass once generated."
}

# ---------------------------------------------------------------------------
# Guest hardware
# ---------------------------------------------------------------------------
variable "vm_memory" {
  type    = number
  default = 8192
}

variable "vm_cores" {
  type    = number
  default = 4
}

variable "vm_disk_size" {
  type    = string
  default = "80G"
}

variable "network_bridge" {
  type    = string
  default = "vmbr0"
}

# ---------------------------------------------------------------------------
# Locale
# ---------------------------------------------------------------------------
variable "locale" {
  type        = string
  default     = "en-US"
  description = "Windows UI/system/input locale"
}

variable "timezone" {
  type        = string
  default     = "UTC"
  description = "Windows time zone name, e.g. UTC or W. Europe Standard Time"
}

# ---------------------------------------------------------------------------
# VirtIO guest tools
# ---------------------------------------------------------------------------
variable "virtio_volume_label_pattern" {
  type        = string
  default     = "virtio-win*"
  description = "Wildcard pattern matched against the mounted VirtIO ISO's volume label, so the build doesn't break when the ISO version (and therefore its label) changes"
}
