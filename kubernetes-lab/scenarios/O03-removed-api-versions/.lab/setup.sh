# O03: manifests with API versions that were removed (policy/v1beta1, networking.k8s.io/v1beta1)
kns legacyweb
kx -n legacyweb create deployment web --image=registry.lab:5000/lab/labapp:1.4 --replicas=2 --dry-run=client -o yaml | ka -f -
kx -n legacyweb create service clusterip web --tcp=8080:8080 --dry-run=client -o yaml | ka -f -
wait_rollout legacyweb deploy/web
! kx apply -f extras.yaml >/dev/null 2>&1 || die "the old API versions were accepted"
