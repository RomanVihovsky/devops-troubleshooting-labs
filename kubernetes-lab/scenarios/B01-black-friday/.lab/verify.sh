web_ok() { [ "$(http_code default http://web.bf.svc:8080/)" = 200 ]; }
deny_kept() { [ "$(kx -n bf get networkpolicy default-deny -o jsonpath='{.spec}' 2>/dev/null)" = "$(recall b01_deny)" ]; }
hpa_ok() { kx -n bf get hpa catalog -o json | jq -e '(.status.currentMetrics // []) as $m
  | ([.status.conditions[]? | select(.type == "ScalingActive" and .status == "True")] | length > 0) and ($m | length > 0)' >/dev/null; }
pdb_ok() {
  kx -n bf get pdb -o json | jq -e '[.items[] | select(.spec.selector.matchLabels.app == "catalog")] as $p
    | ($p | length > 0) and ($p | all(.status.disruptionsAllowed >= 1)) and ($p | any((.spec.minAvailable // 0) >= 2 or ((.spec.maxUnavailable // 0) | tostring) == "1"))' >/dev/null
}
check_eventually 120 "web answers 200 from outside the namespace" web_ok
r=$(load_test default http://web.bf.svc.cluster.local.:8080/ -c 4 -d 20 --rps 20)
loaded() { jq -e '.requests > 200 and .errors == 0' <<<"$r" >/dev/null; }
check "20 s of load: no failed request ($(jq -r '"\(.requests // 0) requests, \(.errors // "?") failed"' <<<"$r"))" loaded
check_eventually 120 "catalog's HPA has CPU metrics and can scale" hpa_ok
check_eventually 60 "catalog's PDB allows a disruption and keeps >= 2" pdb_ok
check "default-deny is unchanged" deny_kept
verdict
