# Q02: the live truth (sourced by verify and solve)
q02_pod() { kx -n nightly get pods -l app=reporting -o jsonpath='{.items[0].metadata.name}'; }
q02_restarted() { kx -n nightly get pod "$(q02_pod)" -o json | jq -r '.status.containerStatuses[] | select(.restartCount > 0) | .name' | head -1; }
q02_field() { kx -n nightly get pod "$(q02_pod)" -o json | jq -r --arg c "$(q02_restarted)" ".status.containerStatuses[] | select(.name == \$c) | .lastState.terminated.$1"; }
q02_limit() { kx -n nightly get pod "$(q02_pod)" -o json | jq -r --arg c "$(q02_restarted)" '.spec.containers[] | select(.name == $c) | .resources.limits.memory'; }
