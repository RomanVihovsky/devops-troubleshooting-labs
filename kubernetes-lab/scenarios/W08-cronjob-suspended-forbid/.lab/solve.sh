for j in $(kx -n cron get cronjob export -o jsonpath='{.status.active[*].name}'); do kx -n cron delete job "$j" --wait=false >/dev/null; done
kx -n cron patch cronjob export -p '{"spec":{"suspend":false}}' >/dev/null
