# ---------------------------------------------------------------------------
# Windows 11 base image — Proxmox VE, built with Packer
#
# Builds an unattended Windows 11 install into a Proxmox VM template using
# the proxmox-iso builder. Requires a Windows 11 ISO and the VirtIO driver
# ISO already uploaded to Proxmox storage (see README.md).
#
# Plugin reference: https://developer.hashicorp.com/packer/integrations/hashicorp/proxmox
# ---------------------------------------------------------------------------
packer {
  required_plugins {
    proxmox = {
      source  = "github.com/hashicorp/proxmox"
      version = ">= 1.2.2"
    }
    windows-update = {
      source  = "github.com/rgl/windows-update"
      version = ">= 0.14.0"
    }
  }
}

locals {
  build_date = formatdate("YYYY-MM-DD", timestamp())
}

source "proxmox-iso" "windows11" {
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
  os                   = "win11"
  machine              = "q35"
  memory               = var.vm_memory
  cores                = var.vm_cores
  sockets              = 1
  cpu_type             = "x86-64-v2-AES"
  qemu_agent           = true
  task_timeout         = "10m"
  pool                 = var.proxmox_vm_pool
  tags = join(";", [
    "os_windows11",
    "build_version_${var.build_version}",
    "build_date_${local.build_date}",
  ])

  # -------------------------------------------------------------------------
  # Firmware / UEFI (required for Windows 11)
  # -------------------------------------------------------------------------
  bios = "ovmf"
  efi_config {
    efi_storage_pool  = var.proxmox_storage_pool
    efi_type          = "4m"
    pre_enrolled_keys = true
  }

  # -------------------------------------------------------------------------
  # TPM 2.0 (required for Windows 11)
  # -------------------------------------------------------------------------
  tpm_config {
    tpm_storage_pool = var.proxmox_storage_pool
    tpm_version      = "v2.0"
  }

  # -------------------------------------------------------------------------
  # Boot
  # -------------------------------------------------------------------------
  boot      = "order=virtio0;ide0"
  boot_wait = "5s"
  boot_command = [
    "<enter><enter>"
  ]

  # -------------------------------------------------------------------------
  # Primary disk
  # -------------------------------------------------------------------------
  scsi_controller = "virtio-scsi-single"
  disks {
    type         = "virtio"
    storage_pool = var.proxmox_storage_pool
    disk_size    = var.vm_disk_size
    cache_mode   = "writeback"
    discard      = true
    io_thread    = true
  }

  # -------------------------------------------------------------------------
  # Windows install ISO — must already be uploaded to Proxmox storage
  # -------------------------------------------------------------------------
  boot_iso {
    type         = "ide"
    iso_file     = var.windows_iso_file
    iso_checksum = "none"
    unmount      = true
  }

  # -------------------------------------------------------------------------
  # Autounattend.xml — Packer builds a small CD on the fly from these files
  # and attaches it. Windows Setup auto-detects and runs Autounattend.xml
  # from WinPE, and separately scans every attached drive's root for a
  # $WinpeDriver$ folder to load storage/network drivers before the disk
  # selection screen (see scripts/pre-build/$WinpeDriver$/*/README.md).
  # -------------------------------------------------------------------------
  additional_iso_files {
    type              = "ide"
    index             = 1
    iso_storage_pool  = var.proxmox_iso_storage_pool
    unmount           = true
    keep_cdrom_device = false
    cd_files = [
      "./scripts/pre-build/build",
      "./scripts/pre-build/$WinpeDriver$",
    ]
    cd_content = {
      "Autounattend.xml" = templatefile("${path.root}/scripts/pre-build/Autounattend.xml.pkrtpl.hcl", {
        admin_password              = var.admin_password
        locale                      = var.locale
        timezone                    = var.timezone
        windows_image_index         = var.windows_image_index
        product_key                 = var.product_key
        virtio_volume_label_pattern = var.virtio_volume_label_pattern
      })
    }
    cd_label = "cidata"
  }

  # -------------------------------------------------------------------------
  # VirtIO drivers — must already be uploaded to Proxmox storage
  # (https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso)
  # -------------------------------------------------------------------------
  additional_iso_files {
    type         = "ide"
    index        = 2
    iso_file     = var.virtio_iso_file
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

  vga {
    type = "qxl"
  }

  # -------------------------------------------------------------------------
  # WinRM — configured over HTTPS with a self-signed cert by
  # scripts/pre-build/build/set-winrm-packer.ps1 during first logon.
  # -------------------------------------------------------------------------
  communicator   = "winrm"
  winrm_username = "Administrator"
  winrm_password = var.admin_password
  winrm_timeout  = "12h"
  winrm_use_ssl  = true
  winrm_insecure = true
}

# ---------------------------------------------------------------------------
# BUILD
# ---------------------------------------------------------------------------
build {
  name    = "windows11"
  sources = ["source.proxmox-iso.windows11"]

  # Fully patch the base image.
  provisioner "windows-update" {
    search_criteria = "IsInstalled=0"
    filters = [
      "exclude:$_.Title -like '*Driver*'",
      "exclude:$_.Title -like '*Preview*'",
      "include:$true",
    ]
    update_limit = 50
  }

  # Answer file used on first boot of VMs cloned from the resulting template
  # (drives sysprep's OOBE pass: random computer name, temp local admin, cleanup).
  provisioner "file" {
    content = templatefile("${path.root}/scripts/post-build/unattend/unattend.xml.pkrtpl.hcl", {
      admin_password = var.admin_password
      locale         = var.locale
      timezone       = var.timezone
    })
    destination = "C:\\Windows\\System32\\Sysprep\\unattend.xml"
  }

  provisioner "powershell" {
    inline = [
      "if (-not (Test-Path 'C:\\Windows\\Setup\\Scripts')) { New-Item -Path 'C:\\Windows\\Setup\\Scripts' -ItemType Directory -Force | Out-Null }"
    ]
  }

  provisioner "file" {
    source      = "scripts/post-build/setupcomplete/SetupComplete.cmd"
    destination = "C:\\Windows\\Setup\\Scripts\\SetupComplete.cmd"
  }

  provisioner "file" {
    source      = "scripts/post-build/setupcomplete/postImage-winrm-reset.ps1"
    destination = "C:\\Windows\\Setup\\Scripts\\postImage-winrm-reset.ps1"
  }

  provisioner "file" {
    source      = "scripts/post-build/unattend/postoobecleanup.cmd"
    destination = "C:\\Windows\\Setup\\Scripts\\postoobecleanup.cmd"
  }

  provisioner "powershell" {
    script = "scripts/post-build/cleanup-for-image.ps1"
  }

  provisioner "powershell" {
    inline = [
      "Write-Host 'Running sysprep and shutting down...'",
      "C:\\Windows\\System32\\Sysprep\\sysprep.exe /generalize /oobe /quiet /shutdown"
    ]
  }
}
