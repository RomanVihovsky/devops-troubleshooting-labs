# Q02 - reading a restart

**Facts**: container `report-builder` (not `web`), reason **OOMKilled**, exit code **137** (128 + SIGKILL 9),
memory limit **192Mi**. The nightly run allocated more than the limit, and the kernel's OOM killer (cgroup
memory.max) killed the process.

**Where it is**
```
kubectl -n nightly get pod -l app=reporting -o jsonpath='{range .status.containerStatuses[*]}{.name} {.restartCount} {.lastState.terminated.reason} {.lastState.terminated.exitCode} {.lastState.terminated.finishedAt}{"\n"}{end}'
kubectl -n nightly logs <pod> -c report-builder --previous     # the last log lines before the kill
kubectl get events -n nightly                                  # only for ~1 h (Q04)
```

**Interview notes**
- Exit codes: 137 = SIGKILL (OOM, or a kill after the grace period), 143 = SIGTERM handled by exiting,
  1/2 = the app's own error. `reason` tells OOMKilled apart from a plain `Error`.
- `lastState` keeps only the **previous** termination. Older history lives in events (short TTL), logs, and
  metrics (`kube_pod_container_status_last_terminated_reason`).
- A container OOM restarts only that container (restartCount per container). The pod and its IP stay.
