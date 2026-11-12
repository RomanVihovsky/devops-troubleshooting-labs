tag_exists() {
  local img t; img=$(kx -n catalog get deploy catalog -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
  case $img in registry.lab:5000/lab/labapp:*) ;; *) return 1 ;; esac
  t=${img##*:}
  curl -fs -o /dev/null --max-time 5 -H 'Accept: application/vnd.oci.image.index.v1+json, application/vnd.docker.distribution.manifest.v2+json, application/vnd.oci.image.manifest.v1+json' \
    "http://192.168.56.20:5000/v2/lab/labapp/manifests/$t"
}
check_eventually 120 "catalog rollout complete, all replicas Ready" deploy_ready catalog catalog
check "still labapp, on a tag that exists" tag_exists
verdict
