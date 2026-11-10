# N03 - the Service's named targetPort no longer exists

**Root cause**: the Service says `targetPort: http`, the containers now name their port `web`. The
EndpointSlice controller can't resolve `http` in the pods, so they get no usable endpoint for that port.

**Fix**: `targetPort: web`.

**Interview notes**
- Named ports are resolved per pod - during a rolling rename, old and new pods can both be served if the
  Service uses a name both define.
- `kubectl get endpointslices -o yaml` shows the resolved port numbers: the first place to look.
