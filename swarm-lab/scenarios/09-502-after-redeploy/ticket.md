# 502/504 from the proxy after every redeploy
**SWARM-109** · Priority P1 · Reporter: on-call

nginx (`proxy`) fronts the `web` service. After this morning's routine redeploy of
`web` (`docker service update --force app_web`) the site returns **502/504** through
every node. `web` itself is healthy (3/3). Restarting the proxy "fixes" it - until
the next deploy of web. Make it survive deploys.

**Done when**
- http://172.30.0.{11,21,22}:8080 return `Hello from ...`
- still true after another `docker service update --force app_web`
  (`./lab verify` does that for you)
