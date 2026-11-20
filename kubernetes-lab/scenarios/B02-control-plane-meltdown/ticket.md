# Nothing gets scheduled, nothing gets replaced, one node is gone
**INC-2910** · P1 · Reporter: on-call

Last night's hardening window touched the control plane and one worker ("verbose logging for the scheduler", "renamed
the controller-manager's kubeconfig to the new naming scheme", "kubelet pointed at the new API port on `k8s-w3`").
This morning: new pods stay *Pending*, Deployments don't create ReplicaSets, `k8s-w3` is *NotReady*. The API server
answers. Undo whatever is needed - the changes were not approved anyway.

**Test**: the scheduler and the controller-manager run and are Ready; a new Deployment in `ops` gets a ReplicaSet and
Running pods; all nodes are Ready; the API answers.
