# edge-cache pods stuck in ImagePullBackOff on k8s-w1 only
**INC-2405** · P3 · Reporter: team edge

`edge-cache` runs one pod per worker. On `k8s-w2` and `k8s-w3` they're fine; on `k8s-w1` the pod sits in
`ImagePullBackOff` for `registry.lab:5000/lab/labapp:1.3`. Last week `k8s-w1` got a "containerd config
refresh" by hand. Nothing else changed.

**Test**: all 3 `edge-cache` pods Running and Ready, including the one on `k8s-w1`; on `k8s-w1` containerd
pulls `registry.lab:5000` images through its registry config again (the config is fixed, not removed).
