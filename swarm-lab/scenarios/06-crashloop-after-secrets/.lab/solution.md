# Solution - secret mounted under a different file name

**Root cause**: `web` uses the short syntax `secrets: [redis_pw]`, which mounts
the secret at `/run/secrets/redis_pw`. The app reads
`REDIS_PASSWORD_FILE=/run/secrets/redis_password` and exits:
`FATAL: cannot read redis password: [Errno 2] No such file or directory`.
Redis works because it uses the long syntax with `target: redis_password`.

**Diagnose**
```
docker service logs app_web
docker service inspect -f '{{json .Spec.TaskTemplate.ContainerSpec.Secrets}}' app_web | jq
# on the node: docker exec <cid> ls -l /run/secrets/
```

**Fix** (either one)
```yaml
    secrets:
      - source: redis_pw
        target: redis_password
```
or `REDIS_PASSWORD_FILE: /run/secrets/redis_pw`.

**Real-world notes**: classic follow-up bug - `echo secret > file` adds a trailing
newline; apps that don't strip it fail auth while `$(cat file)` in a shell strips
it. Secrets are immutable: to rotate, create `redis_pw_v2` and switch services to it.
