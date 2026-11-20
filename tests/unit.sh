#!/usr/bin/env bash
# shellcheck disable=SC2034 # the variables are read by the functions sourced from nirusleep
# Quick checks without root: the pieces nirusleep writes, made from fixtures.
set -euo pipefail
cd "$(dirname "$0")/.."
fail() { echo "FAIL: $*"; exit 1; }
./nirusleep --version | grep -qx "nirusleep $(cat VERSION)" || fail 'version'
sh ./nirusleep --version >/dev/null || fail 'plain sh --version'
./nirusleep help | grep -q 'nirusleep install' || fail 'usage'
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
# Source the functions without running a command.
sed '/^case "${1:-}" in$/,$d' nirusleep | sed '1,/^fi$/d' > "$T/lib.sh"
# shellcheck disable=SC1091
. "$T/lib.sh"
set +e
# The managed block goes in once and out again cleanly.
printf 'GRUB_DEFAULT=0\nGRUB_CMDLINE_LINUX=""\n' > "$T/grub"
cp "$T/grub" "$T/grub.orig"
ROOT_UUID=1111-2222
{ cat "$T/grub"; grub_block 4321; } > "$T/grub.new"
out=$(set +u; . "$T/grub.new"; printf '%s' "$GRUB_CMDLINE_LINUX")
[ "$out" = 'resume=UUID=1111-2222 resume_offset=4321' ] || fail "grub block: $out"
printf 'GRUB_CMDLINE_LINUX="quiet"\n' > "$T/g2"; { cat "$T/g2"; grub_block 7; } > "$T/g2.new"
out=$(set +u; . "$T/g2.new"; printf '%s' "$GRUB_CMDLINE_LINUX")
[ "$out" = 'quiet resume=UUID=1111-2222 resume_offset=7' ] || fail "grub block after quiet: $out"
strip_block "$T/grub.new" > "$T/grub.stripped"
cmp -s "$T/grub.stripped" "$T/grub.orig" || fail 'strip_block does not give the original back'
# The swap file line.
SWAP_FILE=/swap/nirusleep.swap
fstab_block | grep -qx '/swap/nirusleep.swap none swap defaults,pri=0 0 0' || fail 'fstab line'
# Minutes.
valid_minutes 0 && valid_minutes 120 && valid_minutes 10080 || fail 'valid minutes refused'
! valid_minutes 10081 && ! valid_minutes -5 && ! valid_minutes 2h && ! valid_minutes '' || fail 'invalid minutes accepted'
# Arch hooks: resume goes after encrypt, before filesystems; out again on remove.
OS=arch ARCH_CONF=$T/mk BACKUP=$T/b STATE_DIR=$T/s LOG=$T/log
mkdir -p "$T/b"
printf 'MODULES=()\nHOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block plymouth encrypt filesystems fsck)\n' > "$T/mk"
arch_hooks yes
grep -qx 'HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block plymouth encrypt resume filesystems fsck)' "$T/mk" || fail "arch hooks: $(grep HOOKS "$T/mk")"
arch_hooks no
grep -qx 'HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block plymouth encrypt filesystems fsck)' "$T/mk" || fail 'arch hooks not removed'
printf 'HOOKS=(base systemd autodetect block sd-encrypt filesystems)\n' > "$T/mk"
arch_hooks yes
grep -qx 'HOOKS=(base systemd autodetect block sd-encrypt filesystems)' "$T/mk" || fail 'systemd initramfs changed'
# A kernel command line for a Unified Kernel Image keeps its words.
UKI_CMDLINE=$T/cmdline
printf 'root=/dev/mapper/root rw quiet splash resume=UUID=old resume_offset=1\n' > "$T/cmdline"
write_uki_cmdline 99
grep -qx 'root=/dev/mapper/root rw quiet splash resume=UUID=1111-2222 resume_offset=99' "$T/cmdline" || fail "uki cmdline: $(cat "$T/cmdline")"
write_uki_cmdline ''
grep -qx 'root=/dev/mapper/root rw quiet splash' "$T/cmdline" || fail "uki cmdline remove: $(cat "$T/cmdline")"
echo 'unit: ok'
