# NIRUSLEEP

Sleep that saves to disk, for NIRUX laptops. After a while in suspend the
machine writes its memory to an encrypted swap file and switches off
(suspend, then hibernate). A laptop left in a bag keeps its battery, and the
disk password at the next start brings every open window back, in the NIRUX
boot look.

NIRUX installs it as a manifest component and turns it on with
`nirux hibernate on`; the wait is `hibernate_after_minutes` under `[battery]`
in the NIRUX configuration.

## Usage

```sh
sudo nirusleep install [--delay MINUTES] [--on-ac yes|no]   # set up or refresh
sudo nirusleep delay 180      # sleep three hours, then hibernate (0: never)
sudo nirusleep remove         # plain suspend again, swap file gone
nirusleep status [--json]
sudo nirusleep doctor
```

Defaults: 120 minutes, and only on battery (`--on-ac no`): a laptop on its
charger just sleeps. Closing the lid does the same as the suspend key.
`systemctl hibernate` (Void: `zzz -Z`) hibernates at once.

## What it changes

- A swap file the size of the memory: on btrfs `/swap/nirusleep.swap` in a
  subvolume of its own (no snapshot takes it in), on ext4 and xfs
  `/nirusleep.swap`. Existing swap is left alone. A line in `/etc/fstab`.
- `resume=UUID=... resume_offset=...` on the kernel command line: in a block
  of `/etc/default/grub` (every entry, recovery too), and in
  `/etc/kernel/cmdline` for a Unified Kernel Image.
- The initramfs of every kernel resumes before it mounts anything: the
  `resume` hook after `encrypt` on Arch, dracut's `resume` module on Void,
  and on Debian a small script after cryptroot (initramfs-tools' own only
  takes a swap partition).
- `sleep.conf.d` and `logind.conf.d` files for systemd or elogind:
  suspend-then-hibernate after the delay, and the lid uses it.

## Safety

- Only when the root file system is inside LUKS: the image holds the memory,
  passwords included, so it must be encrypted. Never with kernel lockdown
  (Secure Boot), which forbids hibernation.
- Every file is made next to its place, checked and only then moved in; on
  any error everything already changed is put back, the initramfs images
  included. Originals are kept in `/var/lib/nirusleep/backup`, the log is
  `/var/log/nirusleep.log`.
- Every kernel's initramfs is rebuilt and checked, so no boot entry can start
  the system without first reading back a saved image.
- The EFI partition, crypttab, LUKS and the kernel are never touched.

## Tests

`tests/unit.sh` checks the pieces it writes. The real test is NIRUBOOT's VM
harness: `NIRUBOOT_TEST_SLEEP=nirusleep tests/vm-test.sh DISTRO yes` installs
an encrypted Debian, Arch or Void, sets nirusleep up, writes a mark into RAM,
hibernates, starts the machine again, types the disk password on the splash
and checks that the mark survived, then removes nirusleep again.

## Status, disclaimer and how it's made

Part of NIRUX, a personal project. It is written with the help of AI coding
assistants (Claude, OpenCode) and reviewed and tested by its author. Use at
your own risk.

## License

MIT
