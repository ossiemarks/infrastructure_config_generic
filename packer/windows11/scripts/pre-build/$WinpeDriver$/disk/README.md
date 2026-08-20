# Required: VirtIO block storage driver

`windows11.pkr.hcl` attaches the disk as `type = "virtio"` (paravirtualized
VirtIO block device). Windows has no inbox driver for this, so without a
driver here **Windows Setup's partitioning screen will show no disks at
all** and the build will fail immediately.

`$WinpeDriver$` is a folder name Windows Setup automatically scans on every
attached drive during WinPE - any `.inf` files found underneath get loaded
before the disk selection screen. This folder gets baked into the
autounattend CD that Packer generates (`cd_files` in `windows11.pkr.hcl`).

## What to copy here

From the official VirtIO drivers ISO
(https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso),
copy the contents of:

```
viostor\w11\amd64\        (use this if present)
viostor\w10\amd64\        (fallback - compatible with Windows 11)
```

into this folder, so it looks like:

```
$WinpeDriver$/disk/viostor.inf
$WinpeDriver$/disk/viostor.sys
$WinpeDriver$/disk/viostor.cat
$WinpeDriver$/disk/vioser... (whatever else ships alongside viostor for that version)
```

Do this once per VirtIO ISO version you use - re-check the exact driver
filenames each time you update `var.virtio_iso_file`, since content varies
by release.
