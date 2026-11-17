# a rollout restart 12 s into a 50 s load run (the load pod needs a few seconds to start)
url="http://checkout-api.checkout.svc:8080/slow?ms=300"
( sleep 12; kx -n checkout rollout restart deploy/checkout-api >/dev/null 2>&1 ) &
r=$(load_test checkout "$url" -c 8 -d 50)
wait
summary=$(jq -r '"\(.requests // 0) requests, \(.errors // "?") failed"' <<<"$r" 2>/dev/null)
no_errors() { jq -e '.requests > 100 and .errors == 0' <<<"$r" >/dev/null; }
labapp_3() { [ "$(kx -n checkout get deploy checkout-api -o jsonpath='{.spec.replicas} {.spec.template.spec.containers[0].image}')" = "3 registry.lab:5000/lab/labapp:1.4" ]; }
check "a rollout restart under load: no failed request ($summary)" no_errors
check_eventually 120 "checkout-api: 3 Ready replicas" deploy_ready checkout checkout-api 3
check "checkout-api still runs 3 replicas of labapp:1.4" labapp_3
verdict
