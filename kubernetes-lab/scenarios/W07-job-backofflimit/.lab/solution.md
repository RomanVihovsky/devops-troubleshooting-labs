# W07 - BackoffLimitExceeded

**Root cause**: the Job runs `sh /script/report.sh`, but the ConfigMap is mounted at `/scripts`. Every pod exited
1 ("can't open '/script/report.sh'"); after `backoffLimit: 2` retries the Job was marked Failed with
`BackoffLimitExceeded`.

**Diagnosis**
```
kubectl -n batch describe job nightly-report      # Pods Statuses: 0 Active / 0 Succeeded / 3 Failed
kubectl -n batch logs -l job-name=nightly-report --tail=3
kubectl -n batch get job nightly-report -o jsonpath='{.spec.template.spec.containers[0].command} {.spec.template.spec.containers[0].volumeMounts}'
```

**Fix**: the right path, then delete and re-create the Job (its `spec.template` is immutable).

**Interview notes**
- Job knobs: `backoffLimit` (retries, exponential back-off 10 s, 20 s, 40 s...), `activeDeadlineSeconds`,
  `ttlSecondsAfterFinished`, `completions`/`parallelism`, `podFailurePolicy` (e.g. don't retry exit code 2,
  ignore evictions).
- `restartPolicy: Never` keeps every failed pod around for the logs. `OnFailure` restarts the container in
  the same pod, so you lose the earlier attempts' logs except `--previous`.
- Logs of the last attempt: `kubectl logs job/<name>`.
