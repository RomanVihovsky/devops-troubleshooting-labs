# P05: a one-shot migration (exits 0) run as a Deployment - restartPolicy Always restarts it forever
kns orders
ka -f orders.yaml
looping() { [ "$(restarts orders app=orders-migrate)" -ge 2 ]; }
retry 180 looping || die "the migration did not restart"
