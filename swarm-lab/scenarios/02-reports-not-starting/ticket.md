# Reports service never gets a container
**SWARM-102** · Priority P3 · Reporter: data team

The new `reports` service was copied from our data-warehouse stack and deployed.
It shows `0/2` replicas. No container is ever created on any node, nothing in
the logs, no errors on deploy. All three nodes are `Ready` / `Active`.

**Done when**
- `app_reports` is 2/2
- http://172.30.0.11:8080 answers `Hello from ... (reports v1.0)` via every node
