# Pod networking to and from k8s-w3 died after "simplifying" Calico
**INC-2864** · P1 · Reporter: platform team

Yesterday a colleague "simplified" the calico-node DaemonSet (`IP_AUTODETECTION_METHOD`, "the generic recipe from the
docs") and, to be careful, set its
update strategy to `OnDelete`. This morning the calico-node pod on `k8s-w3` was restarted - since then pods on `k8s-w3`
can't reach pods on any other node, and the other way round. Every node in this lab has a NAT interface with the
**same** address `10.0.2.15` besides its host-only address on `192.168.56.0/24`.

**Test**: calico-node is Ready on every node; every node's Calico address is on `192.168.56.0/24`; every `meshcheck` pod
reaches every other one across nodes; calico-node's update strategy rolls changes out to all nodes again.
