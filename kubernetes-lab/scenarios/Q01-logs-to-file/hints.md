## Hint 1
`kubectl -n billing2 exec deploy/invoicer -- ls -l /var/log/labapp/` and `... -- printenv LOG_FILE`. Where do
container logs come from?

## Hint 2
`kubectl logs` shows the container's **stdout/stderr** (the runtime writes them to files on the node). An app that
logs to a file inside the container is invisible there. The classic pattern: a sidecar that follows the file to
its own stdout, both containers sharing the log directory.

## Hint 3
An `emptyDir` volume `logs` mounted at `/var/log/labapp` in the app container and in a sidecar running
`labapp ship-logs /var/log/labapp/app.log` (same image). Apply.
