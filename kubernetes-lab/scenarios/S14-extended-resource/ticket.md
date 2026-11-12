# trainer Pending: Insufficient example.com/gpu
**INC-2508** · P3 · Reporter: team ml

`k8s-w3` got 2 accelerator cards today. Their device plugin ships next week, so nothing tells Kubernetes about
them yet, and `trainer` (it asks for `example.com/gpu: 1`) stays Pending. Until the plugin arrives: advertise the
2 cards on `k8s-w3` by hand so `trainer` can run there. Don't remove the resource request - it's how we stop two
jobs from fighting over one card.

**Test**: `k8s-w3` advertises `example.com/gpu: 2` (capacity and allocatable); `trainer` has 1 Running pod on
`k8s-w3` that still requests `example.com/gpu: 1`.
