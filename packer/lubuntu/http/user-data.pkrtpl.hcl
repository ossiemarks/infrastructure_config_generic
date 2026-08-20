#cloud-config
# Ubuntu Server autoinstall (Subiquity), used here to unattended-install
# Ubuntu 26.04 LTS and then layer the official lubuntu-desktop meta-package
# on top - see the note at the top of lubuntu.pkr.hcl for why.
autoinstall:
  version: 1
  locale: ${locale}
  keyboard:
    layout: ${keyboard_layout}
  timezone: ${timezone}

  # The real interactive login for the deployed machine: a normal
  # sudo-enabled desktop account, password-based (hashed - never plaintext).
  identity:
    hostname: lubuntu
    username: ${local_username}
    password: "${local_password_hash}"

  # Root SSH access is for the Packer build only - re-enabled here just
  # long enough for the build's provisioner to run, then locked back down
  # by scripts/cleanup.sh before the template is sealed. Deploy-time access
  # should go through the identity user above or a cloud-init-provisioned
  # user on clone, not root.
  user-data:
    disable_root: false
  ssh:
    install-server: true
    allow-pw: false
    authorized-keys:
      - ${ssh_public_key}

  storage:
    layout:
      name: lvm

  packages:
    - qemu-guest-agent
    - lubuntu-desktop

  refresh-installer:
    update: true
  updates: all
  shutdown: reboot
