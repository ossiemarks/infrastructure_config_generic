# Base images — Proxmox VE

OpenTofu and Packer are installed locally. This repo builds three
unattended base images as Proxmox VM templates under `packer/`:

| Directory | OS | Install mechanism |
|---|---|---|
| `packer/windows11/` | Windows 11 Pro | Autounattend.xml (WinPE unattended install) |
| `packer/rhel8/` | RHEL 8 | Anaconda kickstart |
| `packer/lubuntu/` | Lubuntu (LXQt) | Ubuntu Server 26.04 LTS autoinstall + `lubuntu-desktop` |

`terraform/windows11-vm/` clones a test VM from the Windows 11 template to
verify the build.

Proxmox VE itself is being deployed manually — nothing here touches that.
Everything below assumes it's already up and reachable.

## Prerequisites (one-time, once Proxmox is up)

1. **Create a Packer API token** in Proxmox: Datacenter → Permissions →
   API Tokens. Give it a role with VM/datastore permissions on the node
   you'll build on. Store the resulting token ID + secret in LastPass.

2. Each build's own README/pkrvars example below covers what install
   media it needs and where to get it — the three OSes differ a lot here
   (Windows and RHEL both require manual downloads from vendor accounts;
   Ubuntu/Lubuntu downloads itself automatically).

## Windows 11 (`packer/windows11/`)

1. **Upload install media to Proxmox storage** (ISO storage, e.g. `local`):
   - Windows 11 ISO — Microsoft doesn't provide a stable scriptable
     download link for the consumer ISO (region-gated JS flow on
     microsoft.com). Download it yourself via the Media Creation Tool or
     your Volume Licensing/Visual Studio subscription, then upload to
     Proxmox (`Datacenter → Storage → ISO Images → Upload`, or `scp` +
     `pvesm`).
   - VirtIO drivers ISO — this one *is* directly downloadable:
     https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso

2. **Populate the VirtIO driver injection folders** — this is the step
   most likely to be skipped and cause a silent build failure. See
   `packer/windows11/scripts/pre-build/$WinpeDriver$/disk/README.md` and
   `.../net/README.md`. Without the disk driver in particular, Windows
   Setup's partition screen will show no disks at all.

3. **Verify the WIM image index** for your specific ISO/edition:
   ```
   dism /Get-WimInfo /WimFile:D:\sources\install.wim
   ```
   Set `windows_image_index` in your `.pkrvars.hcl` to match "Windows 11
   Pro" (or whichever edition you want) — the default of `6` is typical
   for a multi-edition consumer ISO but is not guaranteed.

```
cd packer/windows11
cp pkrvars.hcl.example local.auto.pkrvars.hcl   # fill in real values, do NOT commit
export PKR_VAR_admin_password="$(openssl rand -base64 24 | tr -d '=/+')"
# store that generated password in LastPass now — you'll need it to log into clones

packer init .
packer validate .
packer build .
```

This takes a while (full unattended install + Windows Update pass +
sysprep). Watch for it stalling at the Windows Setup boot screen — that
almost always means the `$WinpeDriver$` disk driver step above was
skipped. Result: a template named `template-<vm_name>-<build_version>`.

On first boot, a clone runs its own OOBE pass (from the `unattend.xml`
baked into the template): random computer name, temporary local account,
then reboots into a clean login screen using the `Administrator` account
and the password you generated above.

**Notes**
- **Product key**: defaults to Microsoft's public generic (KMS client
  setup) key for Windows 11 Pro. This only selects the edition during
  unattended install — it does not license the machine. Replace
  `product_key` with your real Volume License/MAK/retail key, or activate
  separately after deployment.
- **WinRM**: only ever enabled transiently during the build (HTTPS,
  self-signed cert) so Packer can provision the image. It's torn back
  down to OS defaults and stopped before sysprep seals the template —
  clones don't inherit an open WinRM listener.

### Testing the Windows 11 build

`terraform/windows11-vm/` clones a test VM from that template:

```
cd terraform/windows11-vm
cp tfvars.example local.auto.tfvars   # fill in real values, do NOT commit
export TF_VAR_proxmox_api_token="user@realm!tokenid=secret"

tofu init
tofu plan
tofu apply
```

Once Proxmox is confirmed as the real target, point this (or a new
environment under `terraform/`) at production node names/pools instead of
a throwaway test VM ID.

## RHEL 8 (`packer/rhel8/`)

1. **Generate a dedicated build SSH keypair** (used only during the build,
   removed again before the template is sealed):
   ```
   ssh-keygen -t ed25519 -f ~/.ssh/packer_rhel8_ed25519 -N ''
   ```

2. **Upload the RHEL 8 ISO to Proxmox storage.** RHEL requires a Red Hat
   account to download — a free Developer Subscription covers this
   (https://developers.redhat.com). Get the "Binary DVD" ISO (it bundles
   BaseOS + AppStream, which the kickstart installs from directly — no
   subscription-manager registration needed to *build* the image).

```
cd packer/rhel8
cp pkrvars.hcl.example local.auto.pkrvars.hcl   # fill in real values, do NOT commit

packer init .
packer validate .
packer build .
```

**Notes**
- **Registration is deliberately not part of the build.** Baking a
  subscription-manager registration (org/activation key) into a shared
  template would tie every clone to the same registration and burn one
  entitlement per clone indefinitely. Register each deployed VM
  individually instead: `subscription-manager register --auto-attach`.
- **Root has no password and, after `scripts/cleanup.sh` runs, no SSH
  access either** (`PermitRootLogin no`, empty `authorized_keys`). This is
  intentional — deploy-time access should go through a user Proxmox's
  cloud-init creates on clone (set the "User" + SSH key fields in the
  clone's Cloud-Init tab, or the equivalent in `terraform/`), not a
  standing root credential baked into the template.
- **Firewall/SELinux are left at RHEL's secure defaults** (firewalld
  enabled with ssh allowed, SELinux enforcing) — many example kickstarts
  disable both for convenience; this one doesn't, since it's meant to be
  a real base image.

## Lubuntu (`packer/lubuntu/`)

**How this actually works, read before building:** the official Lubuntu
ISO uses the Calamares desktop installer, which has no reliably
documented unattended-install mechanism (unlike Ubuntu Server's Subiquity
autoinstall, which is a first-class, well-supported Packer target). Rather
than reverse-engineer a fragile Calamares automation path, this build
installs Ubuntu Server 26.04 LTS via autoinstall and then installs the
official `lubuntu-desktop` meta-package during setup — the exact same
package a genuine Lubuntu ISO installs. The result is a real Lubuntu
(LXQt) system; only the *install mechanism* differs from using the
Lubuntu ISO directly. If that tradeoff doesn't work for you (e.g. you
need Calamares-specific OEM branding), this isn't the right base to start
from.

1. **Generate a dedicated build SSH keypair:**
   ```
   ssh-keygen -t ed25519 -f ~/.ssh/packer_lubuntu_ed25519 -N ''
   ```

2. **Generate the desktop login's password hash.** macOS's built-in
   `openssl` is LibreSSL and doesn't support `-6` — use the real OpenSSL
   Homebrew already has installed as a dependency:
   ```
   $(brew --prefix openssl@3)/bin/openssl passwd -6 'your password here'
   ```
   Store the plaintext in LastPass, put only the hash in your
   `.pkrvars.hcl`.

No ISO upload needed — Proxmox downloads the Ubuntu ISO directly
(`iso_download_pve = true`). Check
https://releases.ubuntu.com/26.04/ if `ubuntu_iso_url` has moved on to a
newer point release since this was written.

```
cd packer/lubuntu
cp pkrvars.hcl.example local.auto.pkrvars.hcl   # fill in real values, do NOT commit

packer init .
packer validate .
packer build .
```

Installing the full desktop environment takes noticeably longer than a
headless server build — budget more time than the RHEL 8 build.

**Notes**
- **Two separate identities, deliberately:** the `local_username` account
  (password-based, sudo-enabled) is the real interactive desktop login for
  whoever uses a deployed clone. Root SSH access exists only for Packer's
  build and is fully locked down by `scripts/cleanup.sh` before the
  template is sealed (`PermitRootLogin no`, empty `authorized_keys`) —
  same reasoning as RHEL 8 above.
- **Disk size defaults to 40G**, larger than a typical headless server
  template, since `lubuntu-desktop` plus its dependencies need real room.

## General

- **Never commit** the real `local.auto.pkrvars.hcl` / `local.auto.tfvars`
  files, or the RHEL/Lubuntu build SSH private keys — `.gitignore` covers
  the vars files, but the SSH keys live under `~/.ssh/` by default so
  they're outside the repo entirely; keep it that way.
- All three builds tag their Proxmox template/VM with `os_<name>`,
  `build_version_<version>`, and `build_date_<date>` for easy filtering.
