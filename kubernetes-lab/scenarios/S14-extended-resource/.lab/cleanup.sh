# extended resources added to Node status by hand (shared Node objects)
for n in $(cluster_nodes); do
  kx get node "$n" -o jsonpath='{.status.capacity}' | grep -q 'example.com/gpu' \
    && kx patch node "$n" --subresource=status --type=json -p '[{"op":"remove","path":"/status/capacity/example.com~1gpu"}]' >/dev/null 2>&1
done
true
