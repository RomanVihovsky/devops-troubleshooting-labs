kx delete -f rbac.yaml --ignore-not-found >/dev/null
sed -i 's/namespace: default}/namespace: monitor}/' rbac.yaml
kx apply -f rbac.yaml >/dev/null
