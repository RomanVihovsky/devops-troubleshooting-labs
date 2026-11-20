# P16: SHUTDOWN_MODE=immediate and no preStop: SIGTERM races the endpoint removal, in-flight requests fail
kns checkout
ka -f checkout-api.yaml
wait_rollout checkout deploy/checkout-api
