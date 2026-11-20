for i in 0 1; do
  kx -n metrics patch pvc "data-tsdb-$i" -p '{"spec":{"resources":{"requests":{"storage":"2Gi"}}}}' >/dev/null
done
kx -n metrics delete sts tsdb --cascade=orphan >/dev/null
sed -i 's/storage: 1Gi/storage: 2Gi/' tsdb.yaml
ka -f tsdb.yaml
grown() { [ "$(kx -n metrics get pvc data-tsdb-0 data-tsdb-1 -o jsonpath='{range .items[*]}{.status.capacity.storage} {end}')" = "2Gi 2Gi " ]; }
retry 120 grown || true
