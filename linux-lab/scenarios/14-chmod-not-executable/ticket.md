# chmod itself lost its execute bit
**LNX-114** · P2 · Reporter: release team

`/usr/local/bin/deploy.sh` must be executable. But `sudo chmod +x` fails with
`sudo: chmod: command not found` / `Permission denied`: someone ran
`chmod -x /usr/bin/chmod`. No package manager or reinstall allowed (offline box),
no copying binaries in from other machines.

**Test**: `/usr/bin/chmod` is executable again (mode 755, same binary), and
`/usr/local/bin/deploy.sh` is executable and runs.
