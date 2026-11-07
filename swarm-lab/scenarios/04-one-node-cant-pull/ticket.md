# Global agent missing on one node
**SWARM-104** · Priority P2 · Reporter: monitoring team

`node-agent` is a **global** service, so it must run on every node. It shows `2/3`.
One node keeps rejecting the task. Same image, same stack as staging, where it is 3/3.
Nobody "touched" that node, except the config-management run last night.

**Done when**
- `app_agent` runs on all 3 nodes
- http://172.30.0.{11,21,22}:8080 answer `node-agent`
