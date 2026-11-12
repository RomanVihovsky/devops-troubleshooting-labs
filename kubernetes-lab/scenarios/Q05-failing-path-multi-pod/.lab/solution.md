# Q05 - logs across replicas

**Facts**: `GET /items` fails about 30% of the time with 500. The app logs *pricing service timeout* (a
dependency of `/items` only). The other paths are fine.

**How**
```
eval "$(./lab env)"
stern -n edge edge --since 5m | grep -E ' 5[0-9]{2} '        # which path
stern -n edge edge --since 5m -i error                       # what the app says
kubectl -n edge logs -l app=edge --prefix --tail=300 --max-log-requests=6 | grep -i -m5 pricing
```

**Interview notes**
- `kubectl logs -l <selector>` follows at most 5 pods by default (`--max-log-requests`), and `--prefix` adds
  the pod name. stern/kubetail tail all matching pods and pick up new ones.
- Per-request errors at a rate point at a dependency or a code path, not at a pod. Group by path/status first
  (access logs, metrics `labapp_requests_total{code="500"}`), and only then look at a single pod.
- In production: central logs (Loki/Elastic) with labels per pod/namespace, and RED metrics (rate, errors,
  duration) per route so you don't need grep at all.
