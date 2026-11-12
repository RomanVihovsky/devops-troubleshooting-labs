## Hint 1
From a pod in the namespace: `labapp get http://<pod IP>:8080/` vs `kubectl exec <pod> -- labapp get
http://127.0.0.1:8080/`. Which address does the app listen on (`ss -lnt` or the app's settings)?

## Hint 2
port-forward connects to the pod's **localhost**; a Service sends packets to the pod's IP. An app bound to
127.0.0.1 only accepts the first.

## Hint 3
Remove `BIND_ADDRESS: 127.0.0.1` (labapp's default is 0.0.0.0), apply. Inside a pod "all interfaces" is the
pod's own network namespace - restrict access with a NetworkPolicy instead.
