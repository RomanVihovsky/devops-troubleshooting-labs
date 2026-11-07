# Solution - inode exhaustion

**Root cause**: the sessions volume was created with 20000 inodes and holds ~20000 tiny
expired session files (nothing ever cleaned them up). Every new file needs an inode ->
ENOSPC, while the bytes used are ~1%.

**Diagnose**
```
df -h /var/lib/app/sessions      # 1% used
df -i /var/lib/app/sessions      # IUse% 100%
find /var/lib/app/sessions -type f | wc -l
find /var/lib/app/sessions -type f -mtime +1 | wc -l
# find which dir holds the most files on a real box:
sudo du --inodes -x / 2>/dev/null | sort -n | tail
```

**Fix**: `sudo find /var/lib/app/sessions -type f -mtime +1 -delete` - and add a cleanup
job (cron / `systemd-tmpfiles` with an age, e.g. `d /var/lib/app/sessions 0750 - - 1d`).

**Interview notes**: ext4 fixes the inode count at `mkfs` time (`-i`/`-N`); XFS/btrfs
allocate dynamically. `rm *` fails with "Argument list too long" on huge dirs - use
`find -delete`. Typical victims: PHP sessions, mail queues, cache dirs, CI workspaces.
