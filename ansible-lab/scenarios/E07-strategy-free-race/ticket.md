# Deploy fails since `strategy: free` - "has no attribute 'shop_node_id'"
**OPS-3015** · P2 · Reporter: Platform Team

Last week we switched the shop deploy to `strategy: free` (OPS-3011). The per-node steps take very different
times - web2 warms up the big catalog shard, web1 migrates the order history - and with the default strategy
every task waited for the slowest node: ~25 s for three nodes, minutes for the real fleet. Since the switch the
deploy fails on some nodes every time:

```
fatal: [web3]: FAILED! => {"msg": "Task failed: ... object of type 'HostVarsVars' has no attribute 'shop_node_id'"}
```

Reverting to the default strategy makes it pass, but brings the waiting back - not an option. Every node's
`/etc/shop-cluster.conf` has to list all members with their node IDs.

**Test**: `deploy.yml` applies; `/etc/shop-cluster.conf` on every node lists web1, web2 and web3 with their node IDs (from
`/var/lib/shop/node_id`); a deploy finishes in **under 21 s** (the slow steps of different nodes overlap); deploy.yml converges.
