# kv members can't find each other
**INC-2484** · P2 · Reporter: team kv

Our StatefulSet `web` (namespace `kv`) runs 3 members that must reach each other as
`web-0.web.kv.svc.cluster.local`, `web-1.web...`, `web-2.web...`. None of these names resolves. We have a Service
for it (`web-svc`, `workspace/W05/kv.yaml`). Clients that use `web-svc` must keep working.

**Test**: `web-0/1/2.web.kv.svc.cluster.local` resolve to the matching pod's IP from inside the cluster; Service
`web-svc` still answers.
