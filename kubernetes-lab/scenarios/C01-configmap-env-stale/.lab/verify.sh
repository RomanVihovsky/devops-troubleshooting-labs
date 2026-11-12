all_bonjour() { local out; out=$(pods_get promo app=promo /); [ "$(grep -c '^Bonjour from' <<<"$out")" -ge 2 ] && ! grep -q '^Hello from' <<<"$out"; }
from_cm() { kx -n promo get deploy promo -o json | jq -e '.spec.template.spec.containers[0] as $c
  | ([$c.env[]? | select(.name == "GREETING" and .value != null)] | length == 0)
    and (([$c.envFrom[]? | select(.configMapRef.name == "promo-config")] | length > 0)
         or ([$c.env[]? | select(.name == "GREETING" and .valueFrom.configMapKeyRef.name == "promo-config")] | length > 0))' >/dev/null; }
cm_value() { [ "$(kx -n promo get cm promo-config -o jsonpath='{.data.GREETING}')" = Bonjour ]; }
check_eventually 120 "every promo pod says Bonjour" all_bonjour
check "GREETING still comes from ConfigMap promo-config" from_cm
check "promo-config says Bonjour" cm_value
verdict
