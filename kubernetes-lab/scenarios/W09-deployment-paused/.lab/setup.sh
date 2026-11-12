# W09: the Deployment was paused (and left paused); the image change waits
kns blog
kx -n blog create deployment blog --image=registry.lab:5000/lab/labapp:1.3 --replicas=3 --dry-run=client -o yaml | ka -f -
wait_rollout blog deploy/blog
kx -n blog rollout pause deploy/blog >/dev/null
kx -n blog set image deploy/blog labapp=registry.lab:5000/lab/labapp:1.4 >/dev/null
