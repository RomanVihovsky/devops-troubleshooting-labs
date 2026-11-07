# Shop database never starts
**SWARM-101** · Priority P2 · Reporter: backend team

We deployed the shop stack 20 minutes ago. The `db` service (redis) still shows
`0/1` and the shop homepage returns **502 redis error**. There are no logs at all:
`docker service logs app_db` is empty.

The infra team says the database node with SSD storage is "already labelled",
and the stack has the right placement rule. The DB **must** run on the SSD node.

**Done when**
- `app_db` is 1/1 and runs on the SSD node
- http://172.30.0.11:8080 (and .21, .22) answers with a `hits=` counter
