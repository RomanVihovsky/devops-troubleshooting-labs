kx patch storageclass local-path --type json -p '[{"op":"remove","path":"/metadata/annotations/storageclass.kubernetes.io~1is-default-class"}]' >/dev/null
kns wiki
ka -f wiki.yaml
sleep 10
[ "$(kx -n wiki get pvc wiki-data -o jsonpath='{.status.phase}')" = Pending ] || die "PVC not Pending"
