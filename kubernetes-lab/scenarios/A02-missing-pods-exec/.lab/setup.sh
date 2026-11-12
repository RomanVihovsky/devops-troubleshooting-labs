kns team-blue
ka -f rbac.yaml
kx -n team-blue create deployment app --image=registry.lab:5000/lab/labapp:1.4 --dry-run=client -o yaml | ka -f -
