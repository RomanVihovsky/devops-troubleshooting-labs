## Hint 1
`kubectl -n kv get sts web -o jsonpath='{.spec.serviceName}'` and `kubectl -n kv get svc`. Which Service creates
the per-pod DNS names?

## Hint 2
Per-pod DNS records (`<pod>.<service>.<ns>.svc`) exist only for a **headless** Service (`clusterIP: None`) whose
name is the StatefulSet's `serviceName`. `web-svc` is a normal ClusterIP Service with another name.

## Hint 3
Add a Service named `web` with `clusterIP: None`, selector `app: web`, port 8080 (keep `web-svc` for the
clients). The records appear within seconds.
