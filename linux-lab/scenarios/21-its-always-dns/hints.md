## Hint 1
`dig`/`nslookup` talk to the DNS server directly. Applications use the **libc resolver**,
which follows `/etc/nsswitch.conf`. Compare `dig +short api.internal` with `getent hosts api.internal`.
## Hint 2
What does `getent hosts api.internal` return - and where does that answer come from?
Read the `hosts:` line in `/etc/nsswitch.conf` and the contents of `/etc/hosts`.
## Hint 3
There are two problems: a stale `/etc/hosts` entry, and DNS missing from the `hosts:` line.
(`/etc/hosts` is a bind mount in containers: `sed -i` can't replace it - edit in place,
e.g. with `nano`, or `grep -v ... > /tmp/h && cat /tmp/h > /etc/hosts`.)
