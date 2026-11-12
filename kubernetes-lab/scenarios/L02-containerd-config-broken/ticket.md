# k8s-w1 NotReady after the image-pull tuning
**INC-2301** · P2 · Reporter: platform team

To speed up image pulls, someone raised containerd's concurrent downloads on k8s-w1 (`/etc/containerd/
config.toml`) and restarted it. k8s-w1 has been **NotReady** since; `kubectl describe node` mentions the
container runtime. Keep the tuning if you can.

**Test**: containerd is active and enabled on k8s-w1 and its config loads; k8s-w1 is Ready and runs new
pods; containerd's `max_concurrent_downloads` is 10.
