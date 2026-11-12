# catalog release 1.4.0 stuck
**INC-2401** · P3 · Reporter: catalog team

We released `catalog` 1.4.0 (`workspace/P01/catalog.yaml`, namespace `catalog`). The new pods never
start: **ImagePullBackOff**. The old version kept serving for a while, now nothing works.

**Test**: the `catalog` rollout is complete with all replicas Ready, still running the labapp image (an
existing tag of `registry.lab:5000/lab/labapp`).
