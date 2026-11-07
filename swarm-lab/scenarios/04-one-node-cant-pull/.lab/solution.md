# Solution - one node lost its insecure-registry setting

**Root cause**: on worker2, `insecure-registries` was emptied (`[]`) in
`/etc/docker/daemon.json`. The lab registry speaks plain HTTP, so worker2's
dockerd tries HTTPS and fails: `http: server gave HTTP response to HTTPS client`.
The other nodes still have the image or can pull it, so only worker2 rejects the task.

**Diagnose**
```
docker service ps --no-trunc app_agent          # Rejected on worker2 + the HTTPS error
for n in manager1 worker1 worker2; do docker exec lab-$n docker info -f '{{.RegistryConfig.IndexConfigs}}'; done
cat /etc/docker/daemon.json                     # on worker2
```

**Fix** on worker2
```
vi /etc/docker/daemon.json     # add  "insecure-registries": ["registry:5000"]
kill -HUP $(pidof dockerd)     # live-reload (or restart dockerd)
docker info | grep -A2 Insecure
```
Swarm retries the rejected global task automatically.

**Real-world notes**: config drift between nodes is a top cause of "works on
some nodes" issues - diff `docker info` across nodes. In production prefer TLS on
the registry (`/etc/docker/certs.d/<host:port>/ca.crt`) over insecure-registries.
Keys reloadable with SIGHUP: debug, labels, live-restore, insecure-registries,
registry-mirrors, max-concurrent-downloads, ... (see dockerd docs).
