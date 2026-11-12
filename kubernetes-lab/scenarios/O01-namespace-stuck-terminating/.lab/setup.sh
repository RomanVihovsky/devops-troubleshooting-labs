# O01: Backup objects with a finalizer whose operator is gone; the namespace hangs in Terminating
ka -f crd.yaml
kx wait --for=condition=Established crd/backups.example.com --timeout=60s >/dev/null
kns old-team team-z
for b in old-team/nightly old-team/weekly team-z/nightly; do
  ka -f - <<YML
apiVersion: example.com/v1
kind: Backup
metadata: {name: ${b#*/}, namespace: ${b%/*}, finalizers: [example.com/backup-cleanup]}
spec: {schedule: "0 2 * * *", target: s3://backups/${b%/*}}
YML
done
rm -f crd.yaml
kx delete namespace old-team --wait=false >/dev/null
stuck() { kx get ns old-team -o jsonpath='{.status.conditions[*].reason}' | grep -q SomeFinalizersRemain; }
retry 60 stuck || die "old-team is not stuck"
