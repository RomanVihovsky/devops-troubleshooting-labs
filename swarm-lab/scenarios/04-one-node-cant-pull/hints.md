## Hint 1
`docker service ps --no-trunc app_agent` - which node, and what is the full error?
## Hint 2
"http: server gave HTTP response to HTTPS client". Docker talks HTTPS to every
registry unless told otherwise. Compare `docker info` (look for *Insecure Registries*)
on a good node and on the bad node.
## Hint 3
dockerd reads `/etc/docker/daemon.json`. Some keys - including `insecure-registries` -
can be reloaded without restarting the daemon: `kill -HUP $(pidof dockerd)`.
