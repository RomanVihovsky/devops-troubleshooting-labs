kx patch storageclass local-path -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}' >/dev/null
bound() { [ "$(kx -n wiki get pvc wiki-data -o jsonpath='{.status.phase}')" = Bound ]; }
retry 120 bound || true
wait_rollout wiki deploy/wiki
