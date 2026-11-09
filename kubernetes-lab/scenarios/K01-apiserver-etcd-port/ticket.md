# kubectl is dead for everyone - workloads still serve
**INC-1101** · P1 · Reporter: platform team

After the security team's "etcd port audit" on **k8s-cp1** an hour ago, every `kubectl` call fails
(`EOF`, `connection refused`, or a timeout - through `k8s-api.lab` and directly on the node alike).
Apps in the cluster still answer, but nobody can deploy. The auditors say they "only touched config
files under /etc/kubernetes". `./lab node cp1` works.

**Test**: the API answers through `k8s-api.lab` again, the API server is healthy and accepts writes, and
the fix is in its static pod manifest (not a one-off container hack).
