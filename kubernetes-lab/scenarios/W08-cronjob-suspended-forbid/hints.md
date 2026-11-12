## Hint 1
`kubectl -n cron get cronjob export -o wide` (SUSPEND, ACTIVE, LAST SCHEDULE) and `kubectl -n cron get jobs,pods`.

## Hint 2
Two things stop new runs: `suspend: true`, and - with `concurrencyPolicy: Forbid` - a run that is still active.
How long has the active Job been running, and what is it doing?

## Hint 3
Delete the hung Job (`kubectl -n cron delete job <the old one>`), then
`kubectl -n cron patch cronjob export -p '{"spec":{"suspend":false}}'`. Wait for the next minute.
