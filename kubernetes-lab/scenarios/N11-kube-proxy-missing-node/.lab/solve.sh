kx -n kube-system patch ds kube-proxy --type json -p '[{"op":"remove","path":"/spec/template/spec/affinity"}]' >/dev/null
all() { [ "$(kx -n kube-system get ds kube-proxy -o jsonpath='{.status.numberReady}/{.status.desiredNumberScheduled}')" = 4/4 ]; }
retry 180 all || true
