# Solution - services on different overlay networks cannot see each other

**Root cause**: `web` is only on `frontend`, `redis` only on `backend`. Swarm's
embedded DNS resolves service names per network, so from web `redis` does not
resolve (`Name does not resolve`) and there is no route anyway.

**Diagnose**
```
curl -s http://172.30.0.11:8080/           # 502 ... redis error: [Errno -2] Name does not resolve
# on a node running web:
docker exec <cid> nslookup redis 127.0.0.11
docker service inspect -f '{{json .Spec.TaskTemplate.Networks}}' app_web app_redis
```

**Fix**: attach the service that needs the dependency to the dependency's network:
```yaml
  web:
    networks: [frontend, backend]
```
Redis stays backend-only, so the edge still cannot reach it.

**Real-world notes**: the same symptom appears when the service name is wrong
(`redis` vs `app_redis` - both resolve inside the stack, but a different stack's
services need an `external: true` shared network), or when an attachable network
is missing for `docker run` debugging containers.
