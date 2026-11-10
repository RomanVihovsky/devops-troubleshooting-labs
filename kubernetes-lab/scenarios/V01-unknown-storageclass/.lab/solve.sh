sed -i 's/storageClassName: fast-ssd/storageClassName: local-path/' uploads.yaml
kx -n uploads delete pvc uploads-data --wait=false >/dev/null
kx -n uploads delete pod -l app=uploads --wait=false >/dev/null
gone() { ! kx -n uploads get pvc uploads-data >/dev/null 2>&1; }
retry 60 gone
kx apply -f uploads.yaml >/dev/null
wait_rollout uploads deploy/uploads
