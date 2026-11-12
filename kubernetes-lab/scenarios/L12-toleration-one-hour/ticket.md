# checkout degraded for an hour after k8s-w2 failed
**INC-2325** · P2 · Reporter: SRE

k8s-w2 lost its network again (it's still down - hardware is on it, leave it). One of the 3 `api` pods in
`checkout` sat on it and still shows *Running* - nothing replaces it, checkout runs on 2 of 3. Last time it
took over an hour. SLO: pods of a dead node are replaced within **2 minutes**. The manifest is
`workspace/L12/api.yaml`.

**Test**: `checkout/api` has 3 ready pods away from k8s-w2; its tolerations for unreachable / not-ready
nodes are at most 120 s; it still runs 3 replicas.
