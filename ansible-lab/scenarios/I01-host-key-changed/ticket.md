# Redeploy fails: web2 "UNREACHABLE! Host key verification failed"
**OPS-201** · P2 · Reporter: web on-call

`web2` lost its disk last night and was rebuilt from the golden Rocky 9 image (same name, same IP).
It now needs the web role again, but `ansible-playbook site.yml` stops right away:
`web2 | UNREACHABLE! => Failed to connect to the host via ssh: Host key verification failed`.
A colleague suggests `host_key_checking = False` in `ansible.cfg` "until it settles".

Get web2 serving again. Host key checking stays on - and only trust the key after you have made sure
it really is the rebuilt web2 (you have console access: `./lab node web2`).

**Test**: `site.yml` runs cleanly on both nodes (a second run changes nothing); web2 serves the site; the
key you trusted for web2 is web2's real host key; host key checking is not disabled anywhere.
