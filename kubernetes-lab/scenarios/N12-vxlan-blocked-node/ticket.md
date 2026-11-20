# Cross-node pod traffic to and from k8s-w3 is dead
**INC-2758** · P1 · Reporter: platform team

Since the host-firewall rollout on `k8s-w3` (ticket HARD-221: *only DNS and NTP over UDP on the host network*),
pods on `k8s-w3` can't reach pods on other nodes and vice versa; pod-to-pod on the same node works, and the node
itself is Ready. The `meshcheck` DaemonSet runs one echo pod per worker for testing. Security wants the firewall
to stay - fix it so that the cluster works **with** it.

**Test**: every `meshcheck` pod reaches every other one by pod IP across all workers; w3's host firewall (nft table
`host_firewall`) still exists and still drops UDP it doesn't know.
