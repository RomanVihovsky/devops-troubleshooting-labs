# spool-agent never starts on fresh nodes
**INC-2709** · P3 · Reporter: platform team

`spool-agent` (namespace `agent`, `workspace/V09/spool-agent.yaml`) keeps its spool in
`/var/lib/spool-agent` on the node. On our old nodes the directory existed; here the pods stay
**ContainerCreating**. The spool must stay on the node at that path.

**Test**: spool-agent runs on all workers with a hostPath volume at `/var/lib/spool-agent`.
