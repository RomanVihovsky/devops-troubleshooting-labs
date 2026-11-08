# Solution - re-trust a rebuilt host the right way

**Root cause**: the rebuilt web2 generated new SSH host keys. `~/.ssh/known_hosts` still holds the old
one, so OpenSSH refuses the connection - exactly as it would during a man-in-the-middle attack.

**Diagnose**
```
ssh ansible@web2                                   # WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!
ssh-keyscan -t ed25519 web2 | ssh-keygen -lf -     # fingerprint offered over the network
./lab node web2 -> ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub   # fingerprint on the console
```

**Fix**: fingerprints match -> `ssh-keygen -R web2` (+ FQDN, IP), add the new key, run the playbook.

**Interview notes**
* `host_key_checking = False` (or `StrictHostKeyChecking=no`) turns every redeploy into a chance to send
  secrets to an impostor. Never as a default; at most `accept-new` for *first* contact.
* Scale: SSH certificates (`@cert-authority` in known_hosts) make rebuilds a non-event; or publish host keys
  from the provisioning system (cloud-init / CMDB) and template known_hosts with `ansible.builtin.known_hosts`.
* Ansible says "UNREACHABLE" for many SSH problems - always reproduce with plain `ssh -v`.
