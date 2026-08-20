# Anaconda kickstart — RHEL 8
# https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/performing_an_advanced_rhel_installation/kickstart-syntax-reference_installing-rhel-as-an-experienced-user

## Installation source — the mounted DVD itself (BaseOS + AppStream are both
## on the RHEL 8 binary DVD), so no subscription/network repo is needed to
## build this image. Deployed clones still need their own registration -
## see README.md.
cdrom

## Installation environment
text
reboot
firstboot --disable

## Storage and partitioning — wipe disk 0, guided LVM layout
zerombr
clearpart --all --initlabel
autopart --type=lvm

## Network — DHCP on the first interface, enabled at boot
network --bootproto=dhcp --device=link --activate --onboot=on

## Firewall / SELinux — left at RHEL's secure defaults (firewalld enabled
## with ssh allowed, SELinux enforcing). Deliberately not disabled here,
## unlike some example kickstarts - this is meant to be a real base image.
firewall --enabled --service=ssh
selinux --enforcing

## Console and environment
keyboard --vckeymap=${keyboard}
lang ${locale}
skipx
timezone ${timezone} --utc

## Users, groups and authentication — SSH key only, no root password.
## The build-time key is removed by scripts/cleanup.sh before the template
## is sealed.
rootpw --lock
sshkey --username=root "${ssh_public_key}"

%packages
@core
cloud-init
qemu-guest-agent
%end

%post --log=/root/ks-post.log
systemctl enable cloud-init cloud-init-local cloud-config cloud-final qemu-guest-agent
%end
