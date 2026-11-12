for n in $(workers); do kx uncordon "$n" >/dev/null; done
wait_rollout notify deploy/notify
