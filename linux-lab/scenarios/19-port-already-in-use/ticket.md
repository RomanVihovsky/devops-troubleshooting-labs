# nginx can't start: address already in use
**LNX-119** · P1 · Reporter: on-call

After this morning's reboot nginx won't start:
`bind() to 0.0.0.0:80 failed (98: Address already in use)`. Something answers on port 80
with an old "status page" that was decommissioned years ago. We killed the process we
found - port 80 is still taken.

**Test**: nginx is active and serves port 80 (`Server: nginx`), and the old listener
does not come back after a reboot.
