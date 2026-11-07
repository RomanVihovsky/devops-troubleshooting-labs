# Web replicas keep restarting
**SWARM-105** · Priority P1 · Reporter: on-call

After adding a healthcheck (as the platform team demanded), `web` never stabilises.
`docker service ls` mostly shows `0/3`, tasks die after ~20 seconds with
`task: non-zero exit (137)` and get replaced, forever. The app logs look perfectly
normal - it starts and serves requests. Rolling back "is not an option".

**Done when**
- `app_web` is 3/3 and stays up (no task replaced for 20 s)
- the healthcheck is still there
- http://172.30.0.{11,21,22}:8080 answer
