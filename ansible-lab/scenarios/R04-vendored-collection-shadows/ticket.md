# New logrotate task fails: "couldn't resolve module/action 'community.general.logrotate'"
**OPS-293** · P3 · Reporter: web team

We switched our log rotation to the `community.general.logrotate` module (new in community.general 12.5).
The runner image ships community.general **14.0.0** (`ansible-galaxy collection list` shows it), yet the
play fails to find the module.

**Test**: site.yml converges; `/etc/logrotate.d/acme` on web1 rotates `/var/log/acme/*.log` daily, 14 copies;
playbooks in this repo resolve community.general 14.0.0.
