# SSH banner missing on web2 - the deploy failed once, now it's green
**SEC-99** · P3 · Reporter: security

The login banner role failed on the new Rocky node web2 in its handler (`Could not find the requested service
ssh`). The next runs were green, but `ssh web2` still shows no banner. web1 (Debian) is fine.

**Test**: `sshd -T` shows `banner /etc/issue.net` on web1 and web2; a banner config change is applied on both
OS families in one run; site.yml converges.
