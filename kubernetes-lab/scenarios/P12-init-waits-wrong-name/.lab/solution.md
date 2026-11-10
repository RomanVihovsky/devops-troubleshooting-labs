# P12 - the init container waits for a name that no longer exists

**Root cause**: `labapp wait-for postgres` - the Service is now `postgresql`. The init container waits
(up to an hour) for a name that never resolves, the app container never starts: `Init:0/1`.

**Diagnosis**: `kubectl get pods` (Init:0/1), `kubectl logs <pod> -c wait-for-db`, `kubectl get svc`.

**Fix**: wait for `postgresql`.

**Interview notes**
- Init containers run in order, each to completion, before the app containers; a pod is `Init:N/M` until
  then. `Init:CrashLoopBackOff` = an init container exits non-zero.
- "Wait for dependency" init containers are common - but apps should still retry their connections (the DB
  can go away later too).
- Don't write the wait loop as `until nslookup <short-name>` with busybox >= 1.29: its nslookup also tries
  every search domain and exits 1 when any of them answers NXDOMAIN, so it loops forever even when the
  name resolves (dotted names are fine). Use `getent hosts`, a real resolver, or a FQDN.
- Since 1.29, init containers with `restartPolicy: Always` are native sidecars (P14).
