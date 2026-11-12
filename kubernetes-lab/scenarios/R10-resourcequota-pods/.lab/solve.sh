kx -n sandbox patch resourcequota sandbox --type merge -p '{"spec":{"hard":{"pods":"5"}}}' >/dev/null
wait_rollout sandbox deploy/notifier 120
