## Hint 1
`df` counts allocated blocks of the filesystem, `du` walks directory entries. When can a
file use blocks but have no directory entry?
## Hint 2
A deleted file stays allocated while a process still has it open.
`sudo lsof +L1` (link count 0) or `sudo ls -l /proc/*/fd 2>/dev/null | grep deleted`.
## Hint 3
You may not restart the process - but you can shrink the file through its open descriptor:
`: > /proc/<pid>/fd/<n>` (as root).
