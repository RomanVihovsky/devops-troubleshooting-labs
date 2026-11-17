n0=$(coredns_count NXDOMAIN)
# the load pod itself must not search (it resolves per request too): an absolute name
r=$(load_test scanner http://image-scanner.scanner.svc.cluster.local.:8080/ -c 2 -d 20 --rps 10)
n1=$(coredns_count NXDOMAIN)
reqs=$(jq -r '.requests // 0' <<<"$r"); errs=$(jq -r '.errors // "?"' <<<"$r")
nx=$((n1 - n0)); [ "$nx" -lt 0 ] && nx=0
all_ok() { [ "$reqs" -ge 100 ] && [ "$errs" = 0 ]; }
cheap() { [ "$reqs" -ge 100 ] && [ "$nx" -lt "$reqs" ]; }
by_name() {
  kx -n scanner get deploy image-scanner -o json | jq -e '.spec.template.spec as $s
    | ($s.hostAliases // [] | length == 0)
    and ([$s.containers[0].env[] | select(.name == "UPSTREAM_URL") | .value | test("^https?://registry\\.lab\\.?:5000/")] | any)' >/dev/null
}
check "20 s of load: every request succeeds ($reqs requests, $errs failed)" all_ok
check "fewer than 1 NXDOMAIN per request ($nx NXDOMAIN for $reqs requests)" cheap
check "the scanner calls registry.lab by name, no hostAliases" by_name
verdict
