# Q01 - logs that never reach stdout

**Root cause**: `LOG_FILE=/var/log/labapp/app.log` makes the app write its log to a file in the container's
filesystem and nothing to stdout. `kubectl logs` (and any node-level collector such as Fluent Bit or Vector)
only sees what containers write to stdout/stderr: the runtime stores those in
`/var/log/pods/<ns>_<pod>_<uid>/<container>/`.

**Diagnosis**
```
kubectl -n billing2 logs deploy/invoicer                 # empty
kubectl -n billing2 exec deploy/invoicer -- tail -3 /var/log/labapp/app.log
kubectl -n billing2 exec deploy/invoicer -- printenv LOG_FILE
```

**Fix**: keep the file, add a log-shipping sidecar: an `emptyDir` at `/var/log/labapp` shared by the app and a
container running `labapp ship-logs /var/log/labapp/app.log` (`tail -F` would do as well). Its stdout becomes
`kubectl logs deploy/invoicer -c ship-logs`. Simplest of all (if allowed): unset `LOG_FILE` and log to stdout.

**Interview notes**
- 12-factor: log to stdout. The platform ships, rotates (kubelet `containerLogMaxSize`) and retains.
- Since 1.29 a sidecar can be a native sidecar: an init container with `restartPolicy: Always`. It starts
  before and stops after the app, which matters for Jobs (P14).
- A log file in the writable layer counts toward ephemeral storage and disappears with the container. An
  emptyDir survives container restarts, but not pod deletion.
