# Solution - a cross-host dependency inside a `strategy: free` play needs a barrier: split the play

**Root cause**: under `strategy: free` every host runs ahead on its own. web3 (fast) reached "Cluster membership"
seconds before web1 and web2 had finished their migrations and set `shop_node_id`, so the template read
`hostvars['web1'].shop_node_id` - undefined. With the default `linear` strategy all hosts finish task *n* before any
starts *n+1*: correct, but every slow step is paid for by everybody (warm-up 10 s + migration 10 s, plus overhead: ~25 s).

**Fix**: two plays on the same hosts.
```yaml
- name: Deploy the shop cluster      # per node, nobody waits
  hosts: shop
  strategy: free
  tasks: [tools, warm-up, migration, slurp node_id, set_fact shop_node_id]

- name: Shop cluster membership      # barrier: starts when every host has finished play 1
  hosts: shop
  tasks: [template cluster.conf]
```
The slow steps of different nodes still overlap (~16 s instead of ~25 s here) and facts carry over between plays.

**Interview notes**
* `strategy: free` is only safe for tasks that depend on nothing from other hosts (no `hostvars[...]` of runtime
  facts, no `run_once`, no `delegate_to` coordination). Reordering tasks "until it works" is a timing bet.
* Other strategies: `linear` (default), `host_pinned` (like free, but a worker stays with its host), `debug`.
  `serial`, `throttle` and `forks` limit parallelism; none of them is a barrier between hosts inside a play.
* Data other hosts need can also come from a source of truth (inventory/CMDB) instead of runtime facts.
