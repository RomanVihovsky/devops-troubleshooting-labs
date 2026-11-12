# k8s-w1 NotReady since the API endpoint change
**INC-2312** · P2 · Reporter: network team

During a "control-plane endpoint migration" rehearsal someone edited the kubelet's kubeconfig on k8s-w1 and
restarted the kubelet. The migration was cancelled - but k8s-w1 is still **NotReady** (*Kubelet stopped
posting node status*). The other workers are fine.

**Test**: k8s-w1 is Ready and its kubelet talks to the cluster's API endpoint (`k8s-api.lab:6443`).
