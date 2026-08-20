#!/bin/bash
# Final cleanup before this VM is converted into a Proxmox template.
# Leaves the `local_username` desktop account (created by `identity` in
# user-data) untouched - that's the real login for deployed clones. Only
# root's build-time SSH access and machine-specific identifiers are wiped.
set -euxo pipefail

while [ ! -f /var/lib/cloud/instance/boot-finished ]; do
  echo 'Waiting for cloud-init...'
  sleep 1
done

apt-get clean
rm -rf /var/lib/apt/lists/*

cloud-init clean --machine-id --seed
rm -f /etc/hostname
rm -f /etc/ssh/ssh_host_*
rm -f /var/lib/systemd/random-seed

truncate -s 0 /root/.ssh/authorized_keys

sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
