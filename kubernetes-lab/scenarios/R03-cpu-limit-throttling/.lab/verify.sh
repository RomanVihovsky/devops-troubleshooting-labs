res() { kx -n quotes get deploy quotes -o json | jq -c '.spec.template.spec.containers[0].resources'; }
limit_ok() { python3 -c 'import json, sys
r = json.loads(sys.argv[1]); l = (r.get("limits") or {}).get("cpu")
if l is None: sys.exit(0)
v = float(l[:-1]) / 1000 if l.endswith("m") else float(l)
sys.exit(0 if v >= 0.5 else 1)' "$(res)"; }
has_request() { [ -n "$(res | jq -r '.requests.cpu // empty')" ]; }
fast() { local r; r=$(load_test quotes http://quotes.quotes.svc:8080/items -c 4 -d 20 --rps 20)
         jq -e '.requests > 100 and .errors == 0 and .p99_ms < 200' <<<"$r" >/dev/null || { echo "    load: $r" >&2; return 1; }; }
check "CPU limit >= 500m or none" limit_ok
check "still a CPU request" has_request
check_eventually 150 "quotes: 2 Ready pods" deploy_ready quotes quotes 2
check_eventually 90 "20 rps for 20 s: p99 < 200 ms, no errors" fast
verdict
