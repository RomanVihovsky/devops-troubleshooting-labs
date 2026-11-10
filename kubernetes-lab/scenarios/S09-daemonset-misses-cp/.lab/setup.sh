kns logging
ka -f log-agent.yaml
three() { [ "$(kx -n logging get ds log-agent -o jsonpath='{.status.numberReady}')" = 3 ]; }
retry 90 three || die "log-agent not on the 3 workers"
