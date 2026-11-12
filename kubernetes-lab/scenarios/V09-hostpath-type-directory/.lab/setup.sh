for n in $(workers); do nx "$n" 'rm -rf /var/lib/spool-agent' </dev/null; done
kns agent
ka -f spool-agent.yaml
creating() { kx -n agent get pods -o jsonpath='{.items[*].status.containerStatuses[*].state.waiting.reason}' | grep -q ContainerCreating; }
retry 60 creating || die "pods not stuck"
