usd() { [ "$(pods_get pricing app=pricing /env | jq -rs '[.[].CURRENCY] | unique | join(",")' 2>/dev/null)" = USD ]; }
used_cm() { kx -n pricing get deploy pricing -o jsonpath='{.spec.template.spec.containers[0].envFrom[0].configMapRef.name}'; }
cm_ok() { local c; c=$(used_cm); [ -n "$c" ] && [ "$(kx -n pricing get cm "$c" -o jsonpath='{.immutable}/{.data.CURRENCY}')" = true/USD ]; }
check_eventually 150 "pricing: 2 Ready pods" deploy_ready pricing pricing 2
check_eventually 60 "every pod runs with CURRENCY=USD" usd
check "the Deployment's ConfigMap is immutable and holds USD" cm_ok
verdict
