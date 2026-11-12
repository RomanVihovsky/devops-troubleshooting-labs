sed -i 's|path: /readyz|path: /ready|' quorum.yaml
kx apply -f quorum.yaml >/dev/null
kx -n quorum delete pod quorum-0 --wait=false >/dev/null
r3() { [ "$(kx -n quorum get sts quorum -o jsonpath='{.status.readyReplicas}')" = 3 ]; }
retry 180 r3 || true
