# P16 - SIGTERM races the endpoint removal

**Root cause**: when a pod is deleted, two things start **at the same time**: the kubelet runs the preStop hook
(none here) and sends SIGTERM, while the EndpointSlice controller marks the pod terminating and every node's
kube-proxy rewrites its rules. `SHUTDOWN_MODE=immediate` makes the app exit on SIGTERM at once: the requests it is
serving are cut, and for a second or so new connections are still sent to an IP where nothing listens.

**Diagnosis**
```
kubectl -n checkout rollout restart deploy/checkout-api
kubectl -n checkout get endpointslices -w            # the old IP lingers as terminating
kubectl -n checkout get deploy checkout-api -o yaml  # no lifecycle.preStop; SHUTDOWN_MODE=immediate
```

**Fix**: delay SIGTERM until the endpoints have converged:
```yaml
lifecycle:
  preStop:
    exec: {command: ["sleep", "10"]}   # < terminationGracePeriodSeconds (30)
```
The pod keeps serving its in-flight and late-routed requests for 10 s, then exits. The app-side equivalent is a
graceful shutdown that keeps accepting for a while (`SHUTDOWN_MODE=graceful`, `SHUTDOWN_DELAY_SECONDS=10`):
stopping the listener immediately would refuse the late connections just the same.

**Interview notes**
- The grace period covers preStop + the app's own shutdown; when it runs out the kubelet sends SIGKILL.
- `maxUnavailable: 0` + readiness probes protect the **start** of a rollout; preStop protects the **end**.
- Ingress controllers / service meshes add their own propagation delay - the sleep must cover the slowest one.
- Since 1.29 there is also a built-in `lifecycle.preStop.sleep: {seconds: 10}` (no `sleep` binary needed).
