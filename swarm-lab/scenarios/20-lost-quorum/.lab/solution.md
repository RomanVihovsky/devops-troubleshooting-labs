# Solution - recover from lost Raft quorum

**Root cause**: swarm managers replicate state with Raft. A 3-manager cluster
tolerates **1** failure; with 2 managers permanently gone, manager1 is a minority of
one and refuses all writes/reads of cluster state ("does not have a leader").
Workers and running containers are unaffected (data plane keeps working).

**Fix**
```
# on the survivor - keeps services, networks, configs, secrets
docker swarm init --force-new-cluster --advertise-addr 172.30.0.11

docker node ls                                   # old manager2/3 show Down/Unreachable
docker node demote <old-id> && docker node rm <old-id>     # use IDs, not names

docker swarm join-token manager                  # then on manager2 and manager3:
docker swarm join --token SWMTKN-... 172.30.0.11:2377
docker node ls                                   # 1 Leader + 2 Reachable
```

**Aftershock**: the routing mesh on the survivor may stay broken (requests via
manager1:8080 time out, dockerd logs `neighbor entry already exists ... vx-...`):
its ingress overlay kept stale peer entries from before the re-init. Restart dockerd
on that node (`systemctl restart docker`; in the lab `docker restart lab-manager1` on
the host). With 3 managers again, quorum survives the restart.

**Real-world notes**
- Keep an odd number of managers (3 or 5), spread across failure domains.
- Back up `/var/lib/docker/swarm` on a manager (stop dockerd first) - restore with
  `--force-new-cluster` if *all* managers are lost.
- If managers are only temporarily unreachable, do **not** force a new cluster:
  bring them back and quorum returns by itself.
- With autolock enabled you also need the unlock key (`docker swarm unlock`).
