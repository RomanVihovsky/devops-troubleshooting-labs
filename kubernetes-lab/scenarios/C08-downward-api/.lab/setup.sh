# C08: fieldPath status.podIp (case) is rejected by the API; and without a memory limit, limits.memory = node memory
kns inventory
! kx apply -f inventory.yaml >/dev/null 2>&1 || die "the API accepted status.podIp"
