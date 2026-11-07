# Homepage returns 502 after network segmentation
**SWARM-107** · Priority P1 · Reporter: on-call

Security asked us to split the stack into a `frontend` and a `backend` network so
that redis is not exposed to the edge. Since that deploy, the homepage returns
**502** (`redis error`). All services are `Running`, no restarts.

**Done when**
- http://172.30.0.{11,21,22}:8080 answer with a `hits=` counter
- redis is still **only** on the backend network (segmentation stays)
