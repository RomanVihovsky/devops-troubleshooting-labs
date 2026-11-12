image_ok() { [ "$(kx -n vendor get deploy vendor-api -o jsonpath='{.spec.template.spec.containers[0].image}')" = registry.lab:5001/lab/labapp:1.4 ]; }
# the pods' pull secrets (pod spec, or added from the ServiceAccount) exist in vendor and are docker configs
secret_local() {
  local s n=0
  for s in $(kx -n vendor get pods -l app=vendor-api -o jsonpath='{range .items[*]}{range .spec.imagePullSecrets[*]}{.name}{"\n"}{end}{end}' | sort -u); do
    [ "$(kx -n vendor get secret "$s" -o jsonpath='{.type}' 2>/dev/null)" = kubernetes.io/dockerconfigjson ] && n=$((n + 1))
  done
  [ $n -ge 1 ]
}
check_eventually 150 "vendor-api: 2 Ready pods" deploy_ready vendor vendor-api 2
check "still the private image registry.lab:5001/lab/labapp:1.4" image_ok
check "pulled with a pull Secret that lives in vendor" secret_local
check "the private registry still refuses anonymous pulls" private_registry_ok
verdict
