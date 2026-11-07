# Solution - noexec mount option

**Root cause**: `/opt/tools` is a bind mount with `noexec` (from `opt-tools.mount`). The
kernel refuses `execve()` of any file on a `noexec` mount, regardless of mode bits or uid -
root included. systemd reports it as `status=203/EXEC`.

**Diagnose**
```
namei -l /opt/tools/rotate-keys.sh        # modes fine all the way
findmnt -T /opt/tools -o TARGET,SOURCE,OPTIONS   # ...noexec...
systemctl cat opt-tools.mount
```

**Fix** (persistent):
```
sudo sed -i 's/^Options=.*/Options=bind,nosuid,nodev/' /etc/systemd/system/opt-tools.mount
sudo systemctl daemon-reload && sudo systemctl restart opt-tools.mount
```
`mount -o remount,exec /opt/tools` fixes it only until the next re-mount/reboot.

**Interview notes**: `bash script.sh` works on noexec because the kernel executes
`/bin/bash` (on an exec-allowed fs), which merely *reads* the script - so `noexec` is not a
real security boundary for scripts. `/tmp` and `/dev/shm` are often mounted `noexec`,
which breaks installers that unpack and run binaries there. Same symptom from a missing
`x` on a parent dir, SELinux contexts, or a CRLF shebang (`/bin/bash^M: bad interpreter`).
