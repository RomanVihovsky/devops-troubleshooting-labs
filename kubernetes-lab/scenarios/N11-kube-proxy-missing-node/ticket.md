# pricing's new Service times out from k8s-w2
**INC-2857** · P2 · Reporter: team pricing

We launched the `pricing` Service today. Clients on `k8s-w1` and `k8s-w3` reach `pricing.pricing.svc:8080`, but every
pod on `k8s-w2` times out on it - while older Services (e.g. `kubernetes`, our shop) still work from `k8s-w2`. The
pricing pods themselves are healthy. `k8s-w2` was earmarked for the "eBPF pilot" last month; nothing was rolled out
there in the end.

**Test**: kube-proxy runs on every node; `pricing.pricing.svc:8080` is reachable from a pod on each of `k8s-w1`,
`k8s-w2` and `k8s-w3`.
