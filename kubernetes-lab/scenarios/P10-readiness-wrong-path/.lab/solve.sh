sed -i 's|path: /healthz|path: /ready|' quotes.yaml
kx apply -f quotes.yaml >/dev/null
wait_rollout quotes deploy/quotes
