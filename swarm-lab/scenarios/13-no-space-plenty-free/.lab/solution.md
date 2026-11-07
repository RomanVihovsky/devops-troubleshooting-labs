# Solution - inode exhaustion (and immutable volume options)

**Root cause**: the tmpfs volume has `nr_inodes=4096`. At startup the app restores
5000 session files; it runs out of inodes after 4095, and every new session file
fails with ENOSPC - while only ~1% of the *bytes* are used.

**Diagnose**
```
docker exec <cid> df -h /sessions     # 1% used
docker exec <cid> df -i /sessions     # IUse% 100%
docker exec <cid> sh -c 'ls /sessions | wc -l'
docker volume inspect app_sessions    # Options: o=size=256m,nr_inodes=4096   (on the node)
```

**Fix**: more inodes - but note the trap: changing `driver_opts` and redeploying
does **nothing** if `app_sessions` already exists on that node; local volume
options are only read at creation time. Rename the volume (`sessions_v2`) or
`docker volume rm app_sessions` on the node after the task stopped.
(Deleting files fixes it only until the next restart re-imports the snapshot.)

**Real-world notes**: classic victims - mail spools, PHP session dirs, build caches,
Docker's own `/var/lib/docker` with millions of small layer files on ext4
(inodes fixed at mkfs time; XFS/btrfs allocate them dynamically).
