# k8s-w1 keeps going NotReady for a minute, then comes back
**INC-2772** · P2 · Reporter: on-call

`k8s-w1` has been flapping all morning: *NotReady* for a minute or so, then *Ready* again, over and over - pods get
marked for eviction and come back. SSH to the node works perfectly, CPU and memory are low, the kubelet is running.
The network team "tuned the traffic shaping" on that host yesterday.

**Test**: `k8s-w1` stays Ready with a fresh node lease for 2 minutes; no traffic shaping that drops packets remains
on w1's network interfaces.
