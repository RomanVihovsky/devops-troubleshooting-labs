## Hint 1
A filesystem can run out of two different things. `df -h` shows one of them.
## Hint 2
`df -i /var/lib/app/sessions`. How many files are in there (`ls -f | wc -l`, `find ... | wc -l`)?
Every file needs an inode, no matter how small.
## Hint 3
Delete only the stale ones: `find /var/lib/app/sessions -type f -mtime +1` (check, then add `-delete`).
