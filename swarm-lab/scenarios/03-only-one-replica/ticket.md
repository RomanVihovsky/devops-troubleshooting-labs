# report-api 1.4 runs only one replica
**SWARM-103** · Priority P2 · Reporter: dev team

We built `report-api:1.4` on manager1 (`docker build -t lab/report-api:1.4 .`)
and deployed it. The deploy printed a warning we ignored. The service sits at
`1/3` replicas; the other two tasks keep being **rejected** and retried.
"It works on manager1, so the image is fine."

**Done when**
- `app_api` is 3/3 with one replica on each node
- http://172.30.0.{11,21,22}:8080 answer `report-api v1.4`
