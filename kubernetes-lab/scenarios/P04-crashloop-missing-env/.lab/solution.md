# P04 - a required setting is missing

**Root cause**: the app requires `DATABASE_URL` and exits 1 without it ("required setting DATABASE_URL is not
set"); the cleanup renamed the variable to `DB_URL`. Kubernetes restarts it with growing back-off:
CrashLoopBackOff.

**Diagnosis**: `kubectl logs <pod> --previous`, `kubectl describe pod` (Last State: Terminated, Exit Code
1), `kubectl get pod -o jsonpath='{.spec.containers[0].env}'`.

**Fix**: `DATABASE_URL` again.

**Interview notes**
- CrashLoopBackOff is a symptom, not a cause: `--previous` logs + exit code (1 = app error, 137 = SIGKILL /
  OOM, 139 = segfault, 143 = SIGTERM).
- Fail fast on missing config is good app design - the alternative is a pod that runs and does nothing.
- Keep config contracts explicit: a ConfigMap per app, env names documented, `kubectl diff` before apply.
