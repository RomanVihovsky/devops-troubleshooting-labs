# B01: Service selector typo + default-deny without DNS + HPA without CPU requests + PDB with 0 disruptions
kns bf
ka -f storefront.yaml
ka -f policies.yaml
wait_rollout bf deploy/catalog; wait_rollout bf deploy/web
remember b01_deny "$(kx -n bf get networkpolicy default-deny -o jsonpath='{.spec}')"
down() { [ "$(http_code default http://web.bf.svc:8080/)" != 200 ]; }
retry 60 down || die "web already answers"
no_metric() { kx -n bf get hpa catalog -o json | jq -e '[.status.conditions[]? | select(.type == "ScalingActive" and .status == "False")] | length > 0' >/dev/null; }
retry 120 no_metric || die "the HPA has a metric"
