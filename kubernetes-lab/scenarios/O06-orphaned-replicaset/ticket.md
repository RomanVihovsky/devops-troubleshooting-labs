# The retired app still runs
**INC-2601** · P4 · Reporter: FinOps

`oldapp` (namespace `retired`) was retired yesterday: someone ran `kubectl delete deployment oldapp
--cascade=orphan` ("safe mode", from a blog). The Deployment is gone, but 3 `oldapp` pods still run and still use
CPU. Remove what's left of it; the namespace stays (the `keeper` app in it stays too).

**Test**: no ReplicaSet and no pod of `oldapp` remain in `retired`; `keeper` still runs.
