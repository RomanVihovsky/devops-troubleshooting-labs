kns reports
ka -f reports.yaml
err() { kx -n reports get pods -o json | jq -e '[.items[].status.containerStatuses[]? | (.state.waiting.reason // "") + (.lastState.terminated.reason // "")] | any(test("RunContainerError|StartError|ContainerCannotRun|CrashLoopBackOff"))' >/dev/null; }
retry 120 err || die "no RunContainerError"
