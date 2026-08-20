# Clones a test VM from the Windows 11 template built by
# packer/windows11/windows11.pkr.hcl - this is the "initial test" step:
# confirms the template boots, sysprep's OOBE answer file runs correctly,
# and the guest is reachable, before this gets pointed at the real
# Proxmox deployment target.

resource "proxmox_virtual_environment_vm" "windows11_test" {
  name      = var.vm_name
  node_name = var.node_name
  vm_id     = var.vm_id

  clone {
    vm_id = var.template_vm_id
    full  = true
  }

  agent {
    enabled = true
  }
  stop_on_destroy = true

  cpu {
    cores = var.cpu_cores
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = var.memory_mb
  }

  disk {
    interface    = "virtio0"
    datastore_id = var.datastore_id
    size         = var.disk_size
    discard      = "on"
    iothread     = true
  }

  network_device {
    bridge = var.network_bridge
    model  = "virtio"
  }
}

output "vm_id" {
  value = proxmox_virtual_environment_vm.windows11_test.vm_id
}
