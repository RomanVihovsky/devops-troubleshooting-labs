## Hint 1
"No space" can mean two different resources on a filesystem. `df -h` shows one of them.
## Hint 2
`df -i /sessions` - inodes. Every file needs one, no matter how small. How many
files are there (`ls /sessions | wc -l`) and how many inodes does the volume have?
## Hint 3
The volume is a tmpfs created with `nr_inodes=...`. Volume options are applied
**only when the volume is created** - changing the stack file is not enough if
the old volume still exists on the node (`docker volume inspect app_sessions` there).
Give it more inodes and make sure a *new* volume gets created (rename it, or remove the old one).
