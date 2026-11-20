Sleep that saves to disk. After a while in suspend (two hours by default) the
machine writes its memory to an encrypted swap file and switches off; the disk
password at the next start brings every open window back.

- Only on a root file system inside LUKS, and never with kernel lockdown.
- Its own swap file (btrfs: in its own subvolume, so in no snapshot).
- Every kernel and every boot entry resumes; Debian, Arch (also with a
  Unified Kernel Image) and Void.
- `nirusleep delay MINUTES` changes the wait; `nirusleep remove` puts
  everything back.
