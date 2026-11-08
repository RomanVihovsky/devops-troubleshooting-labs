## Hint 1
Run `ssh ansible@web2` from the controller (`./lab ssh web2`): OpenSSH tells you much more than Ansible
does - including which line of `~/.ssh/known_hosts` holds the old key.

## Hint 2
A changed host key is exactly what a man-in-the-middle looks like. Compare the fingerprint the server
offers (`ssh-keyscan -t ed25519 web2 | ssh-keygen -lf -`) with the one on the console
(`./lab node web2`, then `ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub`).

## Hint 3
They match? Remove the stale entries - `ssh-keygen -R web2` (and `web2.acme.internal`, its IP) - add the
new key (`ssh-keyscan -t ed25519 web2 >> ~/.ssh/known_hosts`), then run `ansible-playbook site.yml`.
