# finalizers nobody will remove: strip them, or old-team/team-z hang in Terminating
for ns in old-team team-z; do
  for b in $(kx -n "$ns" get backups.example.com -o name 2>/dev/null); do kx -n "$ns" patch "$b" --type merge -p '{"metadata":{"finalizers":null}}' >/dev/null 2>&1; done
done
true
