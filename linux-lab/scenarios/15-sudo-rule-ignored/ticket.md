# The deploy user's sudo rule does nothing
**LNX-115** · P2 · Reporter: release team

We gave `deploy` the right to restart nginx without a password:
`/etc/sudoers.d/deploy.conf`. `visudo -c` says everything parses OK. Still, as deploy:
`sudo -n systemctl restart nginx` -> `sudo: a password is required`.

Least privilege: deploy must be able to run exactly that, **nothing else** as root.

**Test**: as deploy, `sudo -n systemctl restart nginx` works, `sudo -n id` does not,
and `visudo -c` passes.
