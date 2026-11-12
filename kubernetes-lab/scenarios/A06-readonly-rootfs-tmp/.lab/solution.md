# A06 - read-only rootfs, but the app writes to /tmp

**Root cause**: labapp creates its work directory `/tmp/labapp` at start; with `readOnlyRootFilesystem:
true` that fails (EROFS) and it exits.

**Fix**: an `emptyDir` at `/tmp` (or `WORK_DIR` pointing at a volume) - the rootfs stays read-only.

**Interview notes**
- Read-only rootfs blocks a whole class of attacks (dropping binaries, editing configs). Typical writable
  paths: /tmp, caches, pid/lock files, logs - each becomes an emptyDir.
- `emptyDir.medium: Memory` for /tmp counts against the memory limit.
