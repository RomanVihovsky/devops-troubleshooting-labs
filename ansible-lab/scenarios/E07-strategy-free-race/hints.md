## Hint 1
With `strategy: free` each host runs through the task list as fast as it can - nobody waits at task boundaries.
Which task needs data that *other* hosts produce, and when do the slow hosts produce it? Run it with
`ANSIBLE_CALLBACKS_ENABLED=ansible.posix.profile_tasks` or just watch the order of the output.

## Hint 2
The node ID only exists after a node's migration, so moving tasks around inside the play doesn't remove the race -
on a slow day the order changes again. What you need is a **barrier**: all hosts finish the per-node part before
any host renders the cluster file. In Ansible a play boundary is such a barrier.

## Hint 3
Split `deploy.yml` into two plays on the same hosts: play 1 with `strategy: free` (tools, warm-up, migration, node ID
as a fact), play 2 with the default (linear) strategy that renders `cluster.conf`. Facts set with `set_fact` survive
into the next play. The slow steps still overlap, so it stays fast.
