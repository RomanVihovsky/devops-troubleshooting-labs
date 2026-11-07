## Hint 1
Split the time: `curl -o /dev/null -s -w 'dns:%{time_namelookup} total:%{time_total}\n' http://api.internal:8080/`.
Then `time getent hosts api.internal`.
## Hint 2
Which DNS servers does the resolver use, in which order? `cat /etc/resolv.conf`.
Test each one: `dig @<server> api.internal +time=2 +tries=1`. 5 s is the glibc resolver's default timeout.
## Hint 3
Remove the dead server from `/etc/resolv.conf` (bind mount: edit in place, e.g. `nano`, not `sed -i`).
Watch it live: `sudo tcpdump -ni eth0 port 53` while you curl.
