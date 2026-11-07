## Hint 1
Execute permission is checked at several layers: the file mode, every parent directory,
the **filesystem mount options**, and security modules. `namei -l /opt/tools/rotate-keys.sh`, `findmnt -T /opt/tools`.
## Hint 2
`findmnt -T /opt/tools -o TARGET,SOURCE,OPTIONS`. Which option forbids executing anything
on a mount - even for root?
## Hint 3
The mount comes from a systemd unit (`systemctl cat opt-tools.mount`). Fix its `Options=`,
`daemon-reload`, restart the mount. (`bash /opt/tools/rotate-keys.sh` works as a workaround - why?)
