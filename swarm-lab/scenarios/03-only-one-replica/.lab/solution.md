# Solution - image exists only on the node where it was built

**Root cause**: `lab/report-api:1.4` exists only in manager1's local image store.
On deploy, swarm warned: *"image lab/report-api:1.4 could not be accessed on a
registry to record its digest. Each node will access lab/report-api:1.4
independently..."*. Workers try to pull `docker.io/lab/report-api:1.4`, fail, and
reject the task (`No such image: lab/report-api:1.4`). With
`max_replicas_per_node: 1` swarm cannot pile all replicas onto manager1, so it
stays at 1/3 (without that rule it would silently run all 3 on manager1 - no HA).

**Diagnose**
```
docker service ps --no-trunc app_api        # Rejected ... No such image
docker -H ... images | grep report-api      # only on manager1
```

**Fix**
```
docker tag lab/report-api:1.4 registry:5000/lab/report-api:1.4
docker push registry:5000/lab/report-api:1.4
# stack.yml: image: registry:5000/lab/report-api:1.4  -> docker stack deploy ...
```
(`docker save | ssh worker docker load` on every node also works, but does not scale.)

**Real-world notes**: private registries need `--with-registry-auth` on
`docker stack deploy`, otherwise workers get `pull access denied`. Pin images by
digest (or immutable tags) so every node runs the same bits.
