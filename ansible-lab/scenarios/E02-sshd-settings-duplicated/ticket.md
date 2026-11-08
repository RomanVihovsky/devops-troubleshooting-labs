# Audit: sshd still allows 4 auth tries and X11 forwarding - the hardening run is green
**SEC-82** · P2 · Reporter: security audit

Last week we tightened `sshd_settings` (MaxAuthTries 3, ClientAliveInterval 300 - see `git log`). The run was
green. Today's audit (`sshd -T` on web1) still shows `maxauthtries 4`, `clientaliveinterval 600` and
`x11forwarding yes`. `/etc/ssh/sshd_config` contains some settings twice.

Keep the settings in `sshd_settings` (group_vars).

**Test**: `sshd -T` on web1 shows every value from `sshd_settings`; each managed setting is defined exactly
once (sshd_config + sshd_config.d); a changed value takes effect in one run; site.yml converges.
