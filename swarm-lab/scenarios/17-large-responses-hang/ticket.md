# Downloads hang through one load-balancer node
**SWARM-117** · Priority P2 · Reporter: support

Customers behind LB node **worker2 (172.30.0.22)** report that file downloads
(`/big?kb=512`) hang forever: the response **headers arrive**, then nothing.
Small pages, `/health`, API calls work fine everywhere. The same download through
172.30.0.11 or 172.30.0.21 works instantly. Started after a maintenance on worker2.

```
curl -v --max-time 10 'http://172.30.0.22:8080/big?kb=512' -o /dev/null
```

**Done when**
- `/big?kb=512` downloads completely via every node (3 times each)
