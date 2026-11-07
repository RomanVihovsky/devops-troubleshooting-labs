# Half of the requests hang
**SWARM-115** · Priority P1 · Reporter: on-call

Since last night's maintenance window, roughly every second request to the shop
hangs until the client times out; the others are instant. Requests through
`172.30.0.22` fail almost always. `docker node ls` - all Ready. `docker service ls`
- all N/N. No restarts. App logs only show occasional `redis ... timed out`.
Nobody changed the stack.

**Done when**
- 10 consecutive requests via **each** node answer with `hits=`
