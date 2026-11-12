kns uploads
ka -f uploads.yaml
sleep 10
[ "$(kx -n uploads get pvc uploads-data -o jsonpath='{.status.phase}')" = Pending ] || die "PVC not Pending"
