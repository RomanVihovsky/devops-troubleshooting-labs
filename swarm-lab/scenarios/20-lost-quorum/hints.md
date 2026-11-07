## Hint 1
Raft needs a majority: with 3 managers, 2 must be up. You have 1, and the other two
are never coming back. Restarting dockerd won't conjure the lost Raft members.
`docker info` on manager1 (Managers / Raft section) and on the fresh manager2.
## Hint 2
There is a documented disaster-recovery switch that turns the surviving manager
into a brand-new single-manager cluster **while keeping all state** (services,
networks, secrets): `docker swarm init --help` - look for "force".
## Hint 3
After `docker swarm init --force-new-cluster --advertise-addr 172.30.0.11` on manager1:
the dead managers are still listed - `docker node demote <ID>` then `docker node rm <ID>`
(use IDs, hostnames are duplicated). Then get `docker swarm join-token manager` and
join manager2 and manager3 again.
## Hint 4
Managers healthy, but `http://172.30.0.11:8080` (via manager1) times out while .21/.22 work?
Read manager1's dockerd log from the host: `docker logs lab-manager1 2>&1 | grep -i neighbor`.
After `--force-new-cluster` the survivor's ingress overlay can keep stale neighbour
entries. Restarting dockerd on that node rebuilds it - here: `docker restart lab-manager1`
on the host (= `systemctl restart docker` on a real VM; quorum survives, you have 3 managers now).
