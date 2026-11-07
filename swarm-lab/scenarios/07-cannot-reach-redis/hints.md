## Hint 1
Read the full 502 body (`curl -s 172.30.0.11:8080`) and `docker service logs app_web`.
## Hint 2
Test name resolution from **inside** a web container (on its node):
`docker exec <cid> nslookup redis` / `getent hosts redis`. Swarm's embedded DNS
(127.0.0.11) only answers for services on networks **this container is attached to**.
## Hint 3
`docker service inspect -f '{{json .Spec.TaskTemplate.Networks}}' app_web` vs app_redis.
Who needs to talk to whom?
