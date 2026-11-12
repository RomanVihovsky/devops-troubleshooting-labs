has_readiness() { [ -n "$(kx -n ledger-ui get deploy ledger-ui -o jsonpath='{.spec.template.spec.containers[0].readinessProbe}')" ]; }
check_eventually 60 "http://ledger-ui.ledger-ui/ -> 200 inside the cluster" http_ok ledger-ui http://ledger-ui.ledger-ui/
check "a readiness probe is still configured" has_readiness
verdict
