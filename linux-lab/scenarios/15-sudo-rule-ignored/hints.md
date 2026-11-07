## Hint 1
What does sudo itself think deploy may do? `sudo -l -U deploy`. Is the rule even loaded?
## Hint 2
`grep includedir /etc/sudoers`, then read `man sudoers` - search for "#includedir": which
file names are **skipped** in an include directory?
## Hint 3
Files containing a `.` (or ending in `~`) are ignored. Rename it (keep mode 0440), then `visudo -c`.
