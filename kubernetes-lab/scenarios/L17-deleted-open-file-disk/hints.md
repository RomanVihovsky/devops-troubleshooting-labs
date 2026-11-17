## Hint 1
`df` counts blocks the filesystem has allocated; `du` walks the directory tree. Space can be allocated to a file that
no longer has a name. `./lab node w2`, then `lsof -nP +L1` (or `find /proc/*/fd -lname '*(deleted)'`).

## Hint 2
A process keeps a **deleted** file open - the blocks are freed only when the last file descriptor closes. Which
process, which service? `systemctl status <pid>` names the unit.

## Hint 3
`systemctl disable --now audit-spooler` (killing the process alone isn't enough: systemd restarts it and it
allocates again). The kubelet clears DiskPressure after its transition period (up to 5 minutes); then the pods
come back.
