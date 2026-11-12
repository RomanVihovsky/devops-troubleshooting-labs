# O02: a Database CR with a finalizer of an operator that no longer runs
ka -f crd.yaml
kx wait --for=condition=Established crd/databases.example.com --timeout=60s >/dev/null
rm -f crd.yaml
kns dbs
for d in orders-db inventory-db; do
  ka -f - <<YML
apiVersion: example.com/v1
kind: Database
metadata: {name: $d, namespace: dbs, finalizers: [example.com/drop-database]}
spec: {engine: postgres, size: 10Gi}
YML
done
kx -n dbs delete database orders-db --wait=false >/dev/null
