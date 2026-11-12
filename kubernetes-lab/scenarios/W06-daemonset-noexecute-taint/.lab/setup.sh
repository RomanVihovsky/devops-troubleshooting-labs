# W06: w1 and w2 tainted maintenance=true:NoExecute; the DaemonSet has no toleration
kns logging
ka -f log-agent.yaml
kx taint node k8s-w1 maintenance=true:NoExecute --overwrite >/dev/null
kx taint node k8s-w2 maintenance=true:NoExecute --overwrite >/dev/null
one() { [ "$(kx -n logging get ds log-agent -o jsonpath='{.status.desiredNumberScheduled}/{.status.numberReady}')" = 1/1 ]; }
retry 120 one || die "log-agent is not on w3 only"
