# the pools the student created carry no lab label: remove every non-default pool and its IPAM blocks once the
# batch pods are gone (the default pool lives in 10.244.0.0/16)
kx delete namespace batch --ignore-not-found --wait=true --timeout=180s >/dev/null 2>&1 || true
for p in $(kx get ippools.crd.projectcalico.org -o jsonpath='{.items[*].metadata.name}' 2>/dev/null); do
  [ "$p" = default-ipv4-ippool ] || kx delete ippools.crd.projectcalico.org "$p" --ignore-not-found >/dev/null 2>&1
done
for k in ipamblocks blockaffinities; do
  for o in $(kx get "$k.crd.projectcalico.org" -o jsonpath='{range .items[*]}{.metadata.name}={.spec.cidr}{"\n"}{end}' 2>/dev/null | awk -F= '$2 ~ /^10\.250\./ { print $1 }'); do
    kx delete "$k.crd.projectcalico.org" "$o" --ignore-not-found >/dev/null 2>&1
  done
done
true
