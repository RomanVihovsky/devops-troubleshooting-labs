# W08: a run hung (sleep 3600) and Forbid blocks every new one; then someone suspended the CronJob
kns cron
ka -f - <<'YML'
apiVersion: batch/v1
kind: CronJob
metadata: {name: export, namespace: cron}
spec:
  schedule: "*/1 * * * *"
  concurrencyPolicy: Forbid
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 3
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: Never
          containers:
            - name: export
              image: docker.io/library/busybox:1.37
              command: ["sh", "-c", "echo exporting; sleep 3600"]
YML
active() { [ -n "$(kx -n cron get cronjob export -o jsonpath='{.status.active[*].name}')" ]; }
retry 150 active || die "no run started"
# the "fix" for the hang went into the template, then the CronJob was paused
kx -n cron patch cronjob export --type json -p '[{"op":"replace","path":"/spec/jobTemplate/spec/template/spec/containers/0/command","value":["sh","-c","echo exporting; sleep 2; echo export done"]},{"op":"replace","path":"/spec/suspend","value":true}]' >/dev/null
remember w08_t0 "$(date -u +%FT%TZ)"
