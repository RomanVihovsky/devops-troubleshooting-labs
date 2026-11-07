## Hint 1
Look at the proxy's error log: `docker service logs app_proxy`. Which IP addresses
is it trying to reach? Compare with the current task IPs:
`docker service inspect` / `docker network inspect app_default -v` (on manager1).
## Hint 2
nginx resolves `server web:8000;` in an `upstream` block **once, at startup**, and
caches the IPs forever. How does `web` publish itself in DNS? Check its
`endpoint_mode`. What does `nslookup web` / `nslookup tasks.web` return?
## Hint 3
Make nginx re-resolve at runtime: `resolver 127.0.0.11 valid=2s;` and
`set $up http://web:8000; proxy_pass $up;` (a variable forces per-request resolution).
That's a config change - remember scenario 08 (new config name).
Switching `web` to the default `endpoint_mode: vip` also works, but only if you
**re-create** the service; changing the mode in place leaves stale DNS records.
