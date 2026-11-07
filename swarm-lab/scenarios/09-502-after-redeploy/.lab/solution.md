# Solution - proxy caches stale task IPs (dnsrr + nginx upstream)

**Root cause**: `web` uses `endpoint_mode: dnsrr`, so `web` resolves to the
individual task IPs. nginx resolves hostnames in `upstream` blocks only at
startup. After `service update --force`, every task gets a **new IP**; nginx keeps
sending to the old ones -> `connect() failed (113: Host is unreachable)` /
timeouts -> 502/504.

**Diagnose**
```
docker service logs app_proxy | tail       # upstream: "http://10.10.x.y:8000/" errors
# on manager1, compare with live task IPs:
docker network inspect -v app_default | jq '.[0].Services'
docker exec <proxy cid> nslookup web 127.0.0.11
```

**Fix A (keep dnsrr)**: make nginx re-resolve at runtime (reference fix):
```nginx
resolver 127.0.0.11 valid=2s ipv6=off;
server {
    listen 80;
    location / { set $upstream http://web:8000; proxy_pass $upstream; }
}
```
With a variable in `proxy_pass`, nginx resolves through `resolver` per request
(cached for `valid=`). Deploy it under a new config name (`name: app_nginx_conf_v2`) -
configs are immutable (scenario 08).

**Fix B (stable VIP)**: drop `endpoint_mode: dnsrr` so `web` gets one virtual IP
that survives redeploys. Gotcha: switching the mode **in place** (`stack deploy` /
`service update --endpoint-mode vip`) left the embedded DNS returning stale/empty
records in this Docker version - remove and re-create the service
(`docker service rm app_web && docker stack deploy ...`), then restart the proxy once.

**Real-world notes**: the same bug hits HAProxy (`resolvers` section), Java
(`networkaddress.cache.ttl`), and any client that pools connections forever.
`tasks.<service>` always returns task IPs, regardless of endpoint mode.
