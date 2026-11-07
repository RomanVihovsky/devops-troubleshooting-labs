# Solution - a deleted file that is still open

**Root cause**: `/data/queue.journal` (56 MB) was deleted with `rm`, but `queue-worker`
still holds it open. Deleting only removes the directory entry; the inode and its blocks
stay allocated until the last file descriptor is closed. So `du` (walks names) sees
nothing, `df` (counts blocks) sees a full disk.

**Diagnose**
```
df -h /data; du -sh /data
sudo lsof +L1                              # NLINK 0 -> deleted but open
sudo ls -l /proc/<pid>/fd | grep deleted   # 3 -> /data/queue.journal (deleted)
```

**Fix without restarting** (truncate through the open fd):
```
sudo sh -c ': > /proc/<pid>/fd/3'
```
The process keeps writing (in append mode) to the now-empty file. The clean long-term fix
is log rotation that the app knows about (`copytruncate`, or a signal to reopen files).

**Interview notes**: the #1 "disk full" interview question. Restarting the process also
frees the space (when the fd closes) - often not allowed in production. Also check
`df -i` (inodes, next scenario) and reserved blocks (`tune2fs -l`, 5% for root on ext4).
