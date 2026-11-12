# Q04: 1.4 -> 1.3 -> 1.5 (exits: SESSION_SECRET missing); then every event in the namespace is deleted
kns incident
kx -n incident create deployment api --image=registry.lab:5000/lab/labapp:1.4 --replicas=2 --dry-run=client -o yaml | ka -f -
wait_rollout incident deploy/api
kx -n incident set image deploy/api labapp=registry.lab:5000/lab/labapp:1.3 >/dev/null; wait_rollout incident deploy/api
kx -n incident set image deploy/api labapp=registry.lab:5000/lab/labapp:1.5 >/dev/null
crashing() { crashlooping incident app=api; }
retry 150 crashing || die "1.5 did not crash"
kx -n incident delete events --all >/dev/null
