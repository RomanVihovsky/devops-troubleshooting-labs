# p90 latency is terrible, but the network looks perfect
**SWARM-118** · Priority P2 · Reporter: SRE

Median latency is fine, but p90 is 1-3 seconds and some requests take even longer.
The network team checked: **ping between all nodes < 1 ms, 0% loss**. CPU and memory
are idle everywhere. No errors in any log - "it's just slow sometimes".

```
for i in $(seq 10); do curl -s -o /dev/null -w '%{time_total}\n' http://172.30.0.11:8080/; done
```

**Done when**
- 10 requests via **each** node answer in < 300 ms each
