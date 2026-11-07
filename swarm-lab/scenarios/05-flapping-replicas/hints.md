## Hint 1
Exit code 137 = killed by SIGKILL (128+9). Who killed it? `docker service ps --no-trunc app_web`
shows the reason in the ERROR column.
## Hint 2
"unhealthy container". Inspect the health log of a live container **on its node**:
`docker inspect -f '{{json .State.Health}}' <container> | jq` - read the `Output` field.
## Hint 3
The healthcheck command runs **inside the container**. Does that binary exist in
the image? `docker exec <container> which curl wget python`.
