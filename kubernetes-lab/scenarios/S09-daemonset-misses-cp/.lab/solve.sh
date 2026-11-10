sed -i 's|^      containers:|      tolerations: [{key: node-role.kubernetes.io/control-plane, operator: Exists, effect: NoSchedule}]\n      containers:|' log-agent.yaml
kx apply -f log-agent.yaml >/dev/null
kx -n logging rollout status ds/log-agent --timeout=180s >/dev/null
