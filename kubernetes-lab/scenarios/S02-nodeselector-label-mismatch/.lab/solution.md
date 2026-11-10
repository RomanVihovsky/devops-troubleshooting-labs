# S02 - selector key vs label key

**Root cause**: the pod wants `disktype=ssd`, the node is labelled `disk=ssd`. Same idea, different key:
no node matches.

**Fix**: `nodeSelector: {disk: ssd}` (the platform team owns the label).

**Interview notes**
- `nodeSelector` = exact key/value match; `nodeAffinity` adds operators (In, NotIn, Exists, Gt) and
  preferred (soft) rules.
- Node labels are a contract between platform and app teams - document them; `kubectl get nodes -L <key>`.
- Well-known labels (`kubernetes.io/hostname`, `topology.kubernetes.io/zone`, `node.kubernetes.io/instance-type`)
  are set by the system.
