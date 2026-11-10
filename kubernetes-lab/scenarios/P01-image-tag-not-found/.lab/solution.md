# P01 - the tag doesn't exist

**Root cause**: `labapp:1.4.0` - the registry has `1.4`. The kubelet's pull fails (`manifest unknown` /
`not found`), it backs off exponentially: ErrImagePull → ImagePullBackOff.

**Diagnosis**: `kubectl describe pod` (Events: Failed to pull image ... not found);
`curl http://192.168.56.20:5000/v2/lab/labapp/tags/list`; on a node `crictl pull <image>`.

**Fix**: the right tag.

**Interview notes**
- ImagePullBackOff causes: wrong name/tag, private registry without `imagePullSecrets` (P02), registry
  unreachable/TLS (plain-HTTP registry needs containerd config), rate limits, wrong architecture (P03 is a
  different error: exec format).
- Pin by digest (`image@sha256:...`) for reproducible deploys; tags are mutable.
