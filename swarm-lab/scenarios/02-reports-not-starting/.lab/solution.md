# Solution - resource reservation larger than any node

**Root cause**: `deploy.resources.reservations.memory: 48G`. A reservation is a
scheduling guarantee: swarm only places the task on a node whose *unreserved*
capacity is at least that big. Every node has ~19 GiB, so the task is Pending
with `no suitable node (insufficient resources on 3 nodes)`.

**Diagnose**
```
docker service ps --no-trunc app_reports
docker node inspect -f '{{.Description.Hostname}} {{.Description.Resources.MemoryBytes}}' $(docker node ls -q)
docker service inspect -f '{{json .Spec.TaskTemplate.Resources}}' app_reports
```

**Fix**: set a realistic reservation (e.g. `128M`) and redeploy.

**Real-world notes**: reservations add up - ten services reserving 2G each will
fill a 16G node even if they idle. `limits` cap usage (cgroups) but do not
affect scheduling; `reservations` affect scheduling but do not cap usage.
