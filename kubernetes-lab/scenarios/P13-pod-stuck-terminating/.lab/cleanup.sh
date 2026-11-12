# pods with the orphaned finalizer (and a 600 s grace) would keep namespace queue Terminating
for p in $(kx -n queue get pods -o name 2>/dev/null); do
  kx -n queue patch "$p" --type merge -p '{"metadata":{"finalizers":null}}' >/dev/null 2>&1
done
kx -n queue delete pods --all --grace-period=0 --force >/dev/null 2>&1
true
