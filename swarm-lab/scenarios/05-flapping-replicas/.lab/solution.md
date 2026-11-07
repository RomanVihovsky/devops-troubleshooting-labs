# Solution - healthcheck uses a binary the image does not have

**Root cause**: `test: ["CMD", "curl", ...]` but the image is `python:3.12-alpine`
based: there is no `curl` (only busybox `wget`). Every probe fails with
`exec: "curl": executable file not found in $PATH`; after 3 retries the
container is *unhealthy*, swarm kills it (SIGKILL -> 137) and starts a new one.
Unhealthy/starting tasks also get no routing-mesh traffic, so users see errors.

**Diagnose**
```
docker service ps --no-trunc app_web      # "task: non-zero exit (137): dockerexec: unhealthy container"
# on the node running a task:
docker inspect -f '{{json .State.Health}}' <cid> | jq '.Log[-1].Output'
docker exec <cid> sh -c 'command -v curl wget'
```

**Fix**: use a tool that exists, e.g.
`test: ["CMD", "wget", "-qO-", "http://localhost:8000/health"]`
or `["CMD", "python", "-c", "import urllib.request,sys; urllib.request.urlopen('http://localhost:8000/health')"]`

**Real-world notes**: distroless/scratch images have no shell at all - ship a
tiny healthcheck binary or expose the check inside the app. Exit code 137 can
also mean OOMKilled (see scenario 10) - always check `State.OOMKilled`.
