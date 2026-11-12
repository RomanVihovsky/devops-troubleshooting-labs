for b in $(kx -n old-team get backups -o name 2>/dev/null); do kx -n old-team patch "$b" --type merge -p '{"metadata":{"finalizers":null}}' >/dev/null; done
g() { ! kx get ns old-team >/dev/null 2>&1; }
retry 60 g || true
