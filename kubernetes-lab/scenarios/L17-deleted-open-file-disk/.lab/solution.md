# L17 - space held by a deleted, still-open file

**Root cause**: `audit-spooler.service` (enabled, `Restart=always`) preallocates a spool file of almost the whole
free space, keeps a file descriptor on it, and deletes the name ("rotation by unlinking"). The inode's blocks stay
allocated until the last descriptor closes: `df` sees them, `du` (which walks names) doesn't. The kubelet's
`nodefs.available<10%` threshold sets DiskPressure, taints the node and evicts pods.

**Diagnosis**
```
kubectl describe node k8s-w2 | grep -A2 DiskPressure
./lab node w2
  df -h /var ; du -xsh /var 2>/dev/null
  lsof -nP +L1 | head                         # link count 0 = deleted but open
  ls -l /proc/<pid>/fd | grep deleted
  systemctl status <pid>                      # -> audit-spooler.service
```

**Fix**: `systemctl disable --now audit-spooler` - stopping the process closes the descriptor and frees the space;
disabling keeps it from coming back. (Truncating via `: > /proc/<pid>/fd/3` frees space without stopping a
process you must keep.) DiskPressure clears after the kubelet's `evictionPressureTransitionPeriod` (5 min).

**Interview notes**
- Classic culprits: log rotation with `copytruncate` missing, a container runtime holding deleted log files,
  `rm` on a busy log instead of truncating.
- Kubelet disk signals: `nodefs.available`, `nodefs.inodesFree`, `imagefs.*`; image GC kicks in first, then
  pod eviction by usage over requests (ephemeral-storage).
- `df` vs `du` also differs for files hidden under a mount point and for reserved root blocks.
