# O04: an upgrade killed during --wait leaves the release "pending-upgrade"
kns helmx
helm install web "$LAB_DIR/charts/labapp" -n helmx --set fullnameOverride=web --wait --timeout 3m >/dev/null
# the failed CI run: a broken image, --wait, and the runner killed halfway
helm upgrade web "$LAB_DIR/charts/labapp" -n helmx --set fullnameOverride=web --set image.tag=1.5 --wait --timeout 10m >/dev/null 2>&1 &
hp=$!
pending() { helm status web -n helmx -o json 2>/dev/null | jq -e '.info.status == "pending-upgrade"' >/dev/null; }
retry 60 pending || { kill -9 $hp 2>/dev/null; die "no pending upgrade"; }
sleep 5; kill -9 $hp 2>/dev/null; wait $hp 2>/dev/null || true   # 137: we killed it
# a dry run (changes nothing), output captured first: helm fails here on purpose, and setup runs with pipefail
blocked() { local o; o=$(helm upgrade web "$LAB_DIR/charts/labapp" -n helmx -f values.yaml --dry-run=server 2>&1) || true; grep -q 'another operation' <<<"$o"; }
blocked || die "helm upgrade is not blocked"
