## Hint 1
`grep -nE 'MaxAuthTries|ClientAlive|X11Forwarding' /etc/ssh/sshd_config` on web1 (`./lab node web1`).
For sshd the **first** occurrence of a keyword wins.

## Hint 2
The `regexp` only matches the *commented* default (`#MaxAuthTries 6`). Once it was replaced, or when the
default is not commented (`X11Forwarding yes`), the regexp finds nothing and `lineinfile` **appends** a new line -
after the one sshd actually uses.

## Hint 3
Modern way: render all managed settings into a drop-in, `/etc/ssh/sshd_config.d/10-acme.conf` (included at the
top, so it wins), and remove the managed keywords from the main file (`lineinfile` with `regexp: "^{{ item.key }}\\s"`,
`state: absent` - it removes every match). Then reload sshd.
