hej() { [ "$(pods_get checkout app=checkout / | grep -c '^Hej from')" -ge 2 ]; }
from_cm() { kx -n checkout get deploy checkout -o json | jq -e '[.spec.template.spec.containers[0].envFrom[]? | select(.configMapRef.name == "app-config")] | length > 0' >/dev/null; }
check_eventually 120 "checkout: 2 Ready pods" deploy_ready checkout checkout 2
check_eventually 60 "both greet with Hej" hej
check "the pods read ConfigMap app-config" from_cm
verdict
