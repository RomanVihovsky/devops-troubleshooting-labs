# Solution - placement constraint does not match any node

**Root cause**: the stack requires `node.labels.disk == ssd`, but worker2 was
labelled `disktype=ssd`. Label keys must match exactly, so no node qualifies and
the task stays **Pending** forever. Pending tasks never create a container,
which is why there are no logs.

**Diagnose**
```
docker service ps --no-trunc app_db
#  Pending  "no suitable node (scheduling constraints not satisfied on 3 nodes)"
docker node inspect -f '{{.Description.Hostname}} {{json .Spec.Labels}}' $(docker node ls -q)
#  worker2 {"disktype":"ssd","zone":"c"}
```

**Fix** (either one)
```
docker node update --label-add disk=ssd worker2          # fix the node
# or change the constraint to node.labels.disktype == ssd and redeploy
```

**Real-world notes**: also check `docker node ls` for Drain/Pause availability,
`node.role`/`node.hostname` typos, and `max_replicas_per_node` - all produce the
same "no suitable node" message with a different reason in parentheses.
