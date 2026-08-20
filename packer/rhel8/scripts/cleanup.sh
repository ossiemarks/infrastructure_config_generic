#!/bin/bash
# Final cleanup before this VM is converted into a Proxmox template.
# Removes build-time identifiers and the build-time SSH key so every clone
# gets fresh host keys/machine-id (via cloud-init) and starts with no
# passwordless or key-based root access baked in.
set -euxo pipefail

# cloud-init was installed by the kickstart but never actually configured
# a datasource during this offline build, so there's nothing to wait for
# here unlike the Ubuntu/Debian images — go straight to cleanup.

dnf clean all
rm -rf /var/cache/dnf/*

cloud-init clean --machine-id --seed || true
rm -f /etc/hostname
rm -f /etc/ssh/ssh_host_*
rm -f /var/lib/systemd/random-seed

truncate -s 0 /root/.ssh/authorized_keys

sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config

rm -f /root/ks-post.log
rm -f /root/anaconda-ks.cfg
