# P14 - a sidecar in a Job must be a native sidecar

**Root cause**: `shipper` is an ordinary container. A pod succeeds only when **all** its containers have exited;
`labapp ship-logs` follows the file forever (as Fluent Bit or Vector would), so the pod stays Running and the
Job never completes, although `report` exited 0 long ago.

**Diagnosis**
```
kubectl -n reports get pods                 # READY 1/2, STATUS Running (NotReady)
kubectl -n reports get pod -l job-name=nightly-report \
  -o jsonpath='{range .status.containerStatuses[*]}{.name}={.state}{"\n"}{end}'
```

**Fix**: make the shipper a **native sidecar**: an `initContainers` entry with `restartPolicy: Always`. It
starts before the main container, keeps running beside it, and is stopped by the kubelet once every regular
container has exited, so the pod succeeds and the Job completes. Job pod templates are immutable: delete the
Job and apply the edited manifest.
```yaml
initContainers:
  - name: shipper
    restartPolicy: Always
    image: registry.lab:5000/lab/labapp:1.4
    args: ["ship-logs", "/var/log/report/run.log"]
```

**Interview notes**
- Before native sidecars (alpha 1.28, GA 1.33) the workarounds were a shared "done" file the sidecar polls,
  `shareProcessNamespace` + `pkill`, or Istio's `quitquitquit` endpoint.
- Native sidecars also start **before** the main container and get probes; they are stopped in reverse order
  after the main containers on shutdown, so the last log lines are shipped.
- `activeDeadlineSeconds` would only kill the Job (Failed), not complete it.
