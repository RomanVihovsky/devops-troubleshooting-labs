# Nothing new starts on k8s-w2
**INC-2766** · P2 · Reporter: team shipping

`shipping-api` is pinned to `k8s-w2` (it needs w2's label printer). Since last night's containerd hardening on
that node (HARD-224, *all images from the internal registry*), its pods stay in *ContainerCreating* forever. The
image `registry.lab:5000/lab/labapp:1.4` is fine and cached on the node, and pods that were already running on w2
keep running. There is no internal registry in the lab yet.

**Test**: `shipping-api` runs 2 Ready pods on `k8s-w2`; a brand-new pod on `k8s-w2` starts; the sandbox image
w2's containerd is configured with is available on the node.
