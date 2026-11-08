# Solution - lineinfile regexp must match before *and* after

**Root cause**: `regexp: "^#{{ item.key }} "` matches only the commented default. The first run replaced
`#MaxAuthTries 6`; for `X11Forwarding yes` (not commented) it appended `X11Forwarding no` at the end. When the
values changed, the regexp found nothing and appended again. sshd uses the **first** occurrence, so the new
values never took effect - and the run was green.

**Fix**: a drop-in `/etc/ssh/sshd_config.d/10-acme.conf` (included at the top) with all managed settings, the
same keywords removed from the main file, `sshd -t` before reload. (In-place alternative: `regexp:
"^#?\\s*{{ item.key }}\\s"` plus removing the duplicates.)

**Interview notes**
* lineinfile docs: the regexp should match the line both before and after the change.
* `lineinfile` replaces the **last** match; `state: absent` removes **all** matches.
* Check what the daemon uses (`sshd -T`, `nginx -T`, `postconf -n`), not what the file looks like.
* For whole files prefer `template`; for config dirs prefer drop-ins over editing vendor files.
