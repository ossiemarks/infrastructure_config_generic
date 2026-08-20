# ---------------------------------------------------------------------------
# Lubuntu base image — Proxmox VE, built with Packer
#
# IMPORTANT — how this actually works: the official Lubuntu ISO uses the
# Calamares desktop installer, which does not have a reliably documented
# unattended-install mechanism (unlike Ubuntu Server's Subiquity
# autoinstall). Rather than reverse-engineer a fragile Calamares automation
# path, this builds on the Ubuntu Server ISO's well-supported autoinstall
# and installs the `lubuntu-desktop` meta-package during setup — the exact
# same official package a genuine Lubuntu ISO installs. The end result is a
# real Lubuntu (LXQt) system; only the install *mechanism* differs from
# using the Lubuntu ISO directly. See README.md for the full tradeoff.
#
# Plugin reference: https://developer.hashicorp.com/packer/integrations/hashicorp/proxmox
# ---------------------------------------------------------------------------
packer {
  required_plugins {
    proxmox = {
      source  = "github.com/hashicorp/proxmox"
      version = ">= 1.2.2"
    }
  }
}

locals {
  build_date = formatdate("YYYY-MM-DD", timestamp())
}

source "proxmox-iso" "lubuntu" {
  # -------------------------------------------------------------------------
  # Proxmox connection
  # -------------------------------------------------------------------------
  proxmox_url              = var.proxmox_url
  username                 = var.proxmox_username
  token                    = var.proxmox_token
  node                     = var.proxmox_node
  insecure_skip_tls_verify = var.proxmox_insecure_skip_tls_verify

  # -------------------------------------------------------------------------
  # Guest identity
  # -------------------------------------------------------------------------
  vm_id                = var.vm_id
  vm_name              = "build-${var.vm_name}-${var.build_version}"
  template_name        = "template-${var.vm_name}-${var.build_version}"
  template_description = "${var.template_description} (built ${local.build_date})"
  os                   = "l26"
  machine              = "q35"
  memory               = var.vm_memory
  cores                = var.vm_cores
  sockets              = 1
  cpu_type             = "x86-64-v2-AES"
  qemu_agent           = true
  task_timeout         = "10m"
  pool                 = var.proxmox_vm_pool
  tags = join(";", [
    "os_lubuntu",
    "build_version_${var.build_version}",
    "build_date_${local.build_date}",
  ])

  bios = "seabios"

  # -------------------------------------------------------------------------
  # Proxmox-native cloud-init — separate from the in-guest cloud-init
  # package. Deploy-time access should go through a user cloud-init creates
  # on clone, not the build-time SSH key (see scripts/cleanup.sh / README.md).
  # -------------------------------------------------------------------------
  cloud_init              = true
  cloud_init_storage_pool = var.proxmox_storage_pool

  # -------------------------------------------------------------------------
  # Install ISO — Ubuntu Server 26.04 LTS. Direct public download (Proxmox
  # itself fetches it via iso_download_pve, no pre-upload needed). Check
  # https://releases.ubuntu.com/26.04/ if the filename below has moved on
  # to a newer point release.
  # -------------------------------------------------------------------------
  boot_iso {
    type             = "ide"
    iso_url          = var.ubuntu_iso_url
    iso_checksum     = var.ubuntu_iso_checksum
    iso_storage_pool = var.proxmox_iso_storage_pool
    iso_download_pve = true
    unmount          = true
  }

  # -------------------------------------------------------------------------
  # Boot — GRUB. "c" drops to the GRUB command line, then manually loads
  # the kernel/initrd with the autoinstall + nocloud-net kernel args.
  # -------------------------------------------------------------------------
  boot_wait = var.boot_wait
  boot_command = [
    "c",
    "linux /casper/vmlinuz --- autoinstall 'ds=nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/' ",
    "<enter><wait>",
    "initrd /casper/initrd",
    "<enter><wait>",
    "boot<enter>"
  ]

  http_content = {
    "/meta-data" = file("${path.root}/http/meta-data")
    "/user-data" = templatefile("${path.root}/http/user-data.pkrtpl.hcl", {
      ssh_public_key      = chomp(file(var.ssh_public_key_file))
      local_username      = var.local_username
      local_password_hash = var.local_password_hash
      locale              = var.locale
      keyboard_layout     = var.keyboard_layout
      timezone            = var.timezone
    })
  }

  # -------------------------------------------------------------------------
  # Primary disk
  # -------------------------------------------------------------------------
  scsi_controller = "virtio-scsi-single"
  disks {
    type         = "scsi"
    storage_pool = var.proxmox_storage_pool
    disk_size    = var.vm_disk_size
    cache_mode   = "writeback"
    discard      = true
    io_thread    = true
    ssd          = true
  }

  # -------------------------------------------------------------------------
  # Network
  # -------------------------------------------------------------------------
  network_adapters {
    model    = "virtio"
    bridge   = var.network_bridge
    firewall = true
  }

  # -------------------------------------------------------------------------
  # SSH — the build connects as root using a dedicated build-time keypair
  # (re-enabled via user-data's disable_root, removed by cleanup.sh at the
  # end). The desktop user created by `identity` is left untouched as the
  # real interactive login for the deployed machine.
  # -------------------------------------------------------------------------
  communicator              = "ssh"
  ssh_username              = "root"
  ssh_private_key_file      = var.ssh_private_key_file
  ssh_timeout               = "45m"
  ssh_clear_authorized_keys = true
}

# ---------------------------------------------------------------------------
# BUILD
# ---------------------------------------------------------------------------
build {
  name    = "lubuntu"
  sources = ["source.proxmox-iso.lubuntu"]

  provisioner "shell" {
    script = "scripts/cleanup.sh"
  }
}
