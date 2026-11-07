# worker1 is Down, but the VM is fine
**SWARM-116** · Priority P1 · Reporter: on-call

`docker node ls` shows **worker1 `Down`** since 10 minutes. But the VM is up:
SSH works, `dockerd` is running, `ping manager1` from worker1 works, and containers
on worker1 keep running. The global `node-agent` is missing on worker1 in the swarm view.

worker1 is a "pet" with local state: **do not reboot it** (the node container must
not be restarted) and do not remove it from the swarm.

**Done when**
- worker1 is `Ready` again (without restarting the node)
- `app_agent` runs on all 3 nodes
