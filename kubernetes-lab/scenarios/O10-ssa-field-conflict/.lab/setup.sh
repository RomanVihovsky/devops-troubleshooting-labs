# O10: on-call's server-side "hotfix" apply owns LOG_LEVEL; the pipeline's apply now conflicts
kns inventory
cp inventory-api.yaml "$STATE_DIR/scenario.o10-intended.yaml"
sed 's/value: debug}.*/value: info}/' inventory-api.yaml | kx apply --server-side --field-manager=pipeline-inventory -f - >/dev/null
wait_rollout inventory deploy/inventory-api
kx apply --server-side --field-manager=ops-hotfix --force-conflicts -f - >/dev/null <<'YML'
apiVersion: apps/v1
kind: Deployment
metadata: {name: inventory-api, namespace: inventory}
spec:
  template:
    spec:
      containers:
        - name: api
          env:
            - {name: LOG_LEVEL, value: warn}
YML
wait_rollout inventory deploy/inventory-api
o=$(kx apply --server-side --field-manager=pipeline-inventory --dry-run=server -f inventory-api.yaml 2>&1) && die "the pipeline's apply has no conflict"
grep -q 'conflict with "ops-hotfix"' <<<"$o" || die "unexpected apply error: $o"
