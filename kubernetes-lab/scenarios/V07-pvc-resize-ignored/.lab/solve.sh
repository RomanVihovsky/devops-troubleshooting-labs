kx patch storageclass nfs-standard -p '{"allowVolumeExpansion": true}' >/dev/null
kx apply -f archive.yaml >/dev/null
grown() { [ "$(kx -n archive get pvc archive-data -o jsonpath='{.status.capacity.storage}')" = 2Gi ]; }
retry 120 grown || true
