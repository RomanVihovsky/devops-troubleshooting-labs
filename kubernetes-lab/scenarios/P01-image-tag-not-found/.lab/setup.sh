kns catalog
ka -f catalog.yaml
pull_fail() { kx -n catalog get pods -o jsonpath='{.items[*].status.containerStatuses[*].state.waiting.reason}' | grep -qE 'ErrImagePull|ImagePullBackOff'; }
retry 120 pull_fail || die "no pull error"
