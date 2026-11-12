# P05 - run-to-completion work in a Deployment

**Root cause**: a Deployment's pods must use `restartPolicy: Always`. Its job is "keep N copies running". The
migration exits 0 when it's done, the kubelet restarts it (Always means always), and after a few restarts the
back-off shows up as **CrashLoopBackOff**, although nothing crashed. Every restart re-ran the migration.

**Diagnosis**
```
kubectl -n orders get pods                                   # orders-migrate-... CrashLoopBackOff, RESTARTS 7
kubectl -n orders describe pod -l app=orders-migrate | grep -A4 'Last State'   # Completed, Exit Code 0
kubectl -n orders logs deploy/orders-migrate                 # migrate: ... done
```

**Fix**: delete the Deployment, run the same container as a **Job** (`restartPolicy: Never`/`OnFailure`,
`backoffLimit`, maybe `ttlSecondsAfterFinished`). Per release: a new Job (name with the version), a Helm/Argo CD
hook, or an init container if every pod start may migrate.

**Interview notes**
- CrashLoopBackOff is about **restarts**, not about exit codes. Read `Last State` (reason, exit code) before
  guessing.
- Controllers and restart policies: Deployment/RS/StatefulSet/DaemonSet → Always only; Job → Never/OnFailure;
  CronJob → a Job per schedule. A bare pod accepts any policy.
- Migrations: idempotent, run once per version, and ordered before the new code (hooks: D09).
