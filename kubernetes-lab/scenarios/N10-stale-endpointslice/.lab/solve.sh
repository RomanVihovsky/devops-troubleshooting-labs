kx -n legacy patch svc db -p '{"spec":{"selector":{"app":"pg-new"}}}' >/dev/null
kx -n legacy delete endpointslice db-manual >/dev/null
wait_rollout legacy deploy/orders 180 || true
