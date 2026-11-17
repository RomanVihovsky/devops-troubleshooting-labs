# search-api only gets half its replicas
**INC-2631** · P3 · Reporter: team search

We copied `search-api` from the production cluster (`workspace/S05/search-api.yaml`): 4 replicas, spread evenly
over the zones. Here 2 pods run and 2 stay *Pending* - "didn't match pod topology spread constraints" - although
the workers are nearly idle. The lab has two zones: `zone-a` (`k8s-w1`, `k8s-w2`) and `zone-b` (`k8s-w3`). The
replicas must stay spread over both zones as evenly as possible.

**Test**: `search-api` runs 4 Ready replicas; both zones have 2 of them; a zone topology spread constraint is
still in place.
