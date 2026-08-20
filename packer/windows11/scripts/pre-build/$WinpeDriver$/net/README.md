# Optional: VirtIO network driver

Not required for Setup to see the disk, but including it here means the
network adapter (`model = "virtio"` in `windows11.pkr.hcl`) works
immediately at first boot, before `start-virtio-install.ps1` (which
installs the full guest-tools package) gets a chance to run. Without it,
first boot has no network connectivity until that script completes, which
can make the WinRM handshake slower to come up.

## What to copy here

From the official VirtIO drivers ISO
(https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso),
copy the contents of:

```
NetKVM\w11\amd64\        (use this if present)
NetKVM\w10\amd64\        (fallback - compatible with Windows 11)
```

into this folder.
