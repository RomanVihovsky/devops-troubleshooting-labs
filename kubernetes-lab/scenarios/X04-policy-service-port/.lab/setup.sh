# X04: the policy allows the Service port (80), the pod listens on 8080
kns portx
kx -n portx create deployment web --image=registry.lab:5000/lab/labapp:1.4 --dry-run=client -o yaml | ka -f -
wait_rollout portx deploy/web
ka -f web.yaml
! tcp_ok_as portx - web.portx.svc:80 || die "web is reachable"
