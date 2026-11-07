# Billing cannot reach the legacy API - from inside swarm only
**SWARM-119** · Priority P1 · Reporter: billing team

`billing` must call the legacy billing API that runs **outside** swarm at
`http://172.30.0.50:8080/`. Its `/health` is red:
`upstream http://172.30.0.50:8080/: <urlopen error timed out>`.

From every swarm node (VM) the API works: `curl 172.30.0.50:8080` -> `legacy-billing-api OK`.
The firewall team swears nothing is blocked. The platform team created the app
network "with the standard company subnet".

**Done when**
- `/health` on billing returns 200 via every node
