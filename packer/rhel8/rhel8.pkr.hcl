# ---------------------------------------------------------------------------
# RHEL 8 base image — Proxmox VE, built with Packer
#
# Unattended install via Anaconda kickstart, served by Packer's built-in
# HTTP server. Installs from the mounted DVD itself (BaseOS + AppStream are
# both on the RHEL 8 binary DVD ISO) rather than a network repo, so the
# build needs no Red Hat subscription/registration - only individual VMs
# cloned from the resulting template need to register (see README.md).
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

source "proxmox-iso" "rhel8" {
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
    "os_rhel8",
    "build_version_${var.build_version}",
    "build_date_${local.build_date}",
  ])

  # -------------------------------------------------------------------------
  # Firmware — legacy BIOS. Simpler boot_command (Anaconda's isolinux menu),
  # and RHEL has no UEFI/TPM requirement the way Windows 11 does.
  # -------------------------------------------------------------------------
  bios = "seabios"

  # -------------------------------------------------------------------------
  # Proxmox-native cloud-init (separate from the in-guest cloud-init package
  # installed by the kickstart below) — lets clones get SSH keys/IP/hostname
  # injected via Proxmox itself, no per-clone kickstart needed.
  # -------------------------------------------------------------------------
  cloud_init              = true
  cloud_init_storage_pool = var.proxmox_storage_pool

  # -------------------------------------------------------------------------
  # Boot — RHEL 8's DVD boots isolinux (BIOS) with a text boot menu; <tab>
  # edits the highlighted entry's kernel command line.
  # -------------------------------------------------------------------------
  boot_wait = var.boot_wait
  boot_command = [
    "<tab>",
    "<bs><bs><bs><bs><bs>",
    "inst.text inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg ",
    "<wait><enter>"
  ]

  http_content = {
    "/ks.cfg" = templatefile("${path.root}/http/ks.cfg.pkrtpl.hcl", {
      ssh_public_key = chomp(file(var.ssh_public_key_file))
      timezone       = var.timezone
      keyboard       = var.keyboard
      locale         = var.locale
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
  # Install ISO — RHEL requires a Red Hat account to download, so this must
  # already be uploaded to Proxmox storage (see README.md).
  # -------------------------------------------------------------------------
  boot_iso {
    type         = "ide"
    iso_file     = var.rhel_iso_file
    iso_checksum = "none"
    unmount      = true
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
  # SSH — a dedicated build-time keypair, installed via the kickstart's
  # `sshkey` directive and removed again by scripts/cleanup.sh before the
  # template is sealed. Root has no password (`rootpw --lock`).
  # -------------------------------------------------------------------------
  communicator              = "ssh"
  ssh_username              = "root"
  ssh_private_key_file      = var.ssh_private_key_file
  ssh_timeout               = "30m"
  ssh_clear_authorized_keys = true
}

# ---------------------------------------------------------------------------
# BUILD
# ---------------------------------------------------------------------------
build {
  name    = "rhel8"
  sources = ["source.proxmox-iso.rhel8"]

  provisioner "shell" {
    script = "scripts/cleanup.sh"
  }
}
