# k8s-w3 NotReady after the disk cleanup
**INC-2309** · P2 · Reporter: platform team

A "cleanup old config" script ran on k8s-w3 this morning. Now the node is **NotReady**: *container
runtime network not ready: NetworkReady=false ... cni config uninitialized*. Pods already running there
are fine; new ones can't start.

**Test**: k8s-w3 is Ready; it has a CNI config again; a new pod on k8s-w3 gets an IP and reaches a
Service.
