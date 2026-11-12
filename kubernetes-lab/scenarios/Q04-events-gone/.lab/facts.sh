# Q04: the live truth
q04_rs() { kx -n incident get rs -l app=api -o json | jq -r --arg r "$1" '.items[] | select(.metadata.annotations["deployment.kubernetes.io/revision"] == $r) | .spec.template.spec.containers[0].image'; }
q04_rev() { kx -n incident get deploy api -o jsonpath='{.metadata.annotations.deployment\.kubernetes\.io/revision}'; }
q04_bad() { q04_rs "$(q04_rev)"; }
q04_good() { q04_rs "$(( $(q04_rev) - 1 ))"; }
q04_pod() { kx -n incident get pods -l app=api -o json | jq -r '.items[] | select(.status.containerStatuses[0].restartCount > 0) | .metadata.name' | head -1; }
q04_exit() { kx -n incident get pod "$(q04_pod)" -o jsonpath='{.status.containerStatuses[0].lastState.terminated.exitCode}'; }
