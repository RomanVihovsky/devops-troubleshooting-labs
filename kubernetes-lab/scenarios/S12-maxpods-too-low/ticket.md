# New deployments can't schedule anywhere
**INC-2417** · P2 · Reporter: team reports

Our new `reports` deployment (3 small pods) stays Pending: *0/4 nodes are available: 1 node(s) had untolerated
taint ..., 3 Too many pods*. The workers sit at 20% CPU and memory. Last week the capacity team "right-sized"
the workers' kubelet configuration to "what each node runs today". Undo the damage so normal growth works again.

**Test**: the 3 `reports` pods Running; every worker's kubelet allows at least the Kubernetes default of 110 pods
(the setting is fixed in the kubelet configuration, so it survives a kubelet restart); all nodes Ready.
