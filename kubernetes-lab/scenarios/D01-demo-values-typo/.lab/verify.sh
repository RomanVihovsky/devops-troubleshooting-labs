demo_body() { curl -s --max-time 5 -H 'Host: demo.lab' -H "Authorization: Bearer $(cat "$STATE_DIR/demo-token")" http://192.168.56.200/; }
bonjour() { demo_body | grep -q '^Bonjour'; }
tags_exist() {
  local t img
  for img in $(kx -n demo get pods -l app.kubernetes.io/instance=demo -o jsonpath='{.items[*].spec.containers[*].image}'); do
    t=${img##*:}
    curl -fs -o /dev/null --max-time 5 -H 'Accept: application/vnd.oci.image.index.v1+json, application/vnd.docker.distribution.manifest.v2+json, application/vnd.oci.image.manifest.v1+json' \
      "http://192.168.56.20:5000/v2/lab/labapp/manifests/$t" || return 1
  done
}
rolled_out() { kx -n demo rollout status deploy/demo --timeout=5s >/dev/null 2>&1; }
git_values() {
  gx "/repos/lab/gitops/raw/envs/demo/values.yaml?ref=main" | python3 -c 'import sys, yaml
d = yaml.safe_load(sys.stdin); a = d.get("app") or {}
sys.exit(0 if a.get("greeting") == "Bonjour" else 1)'
}
check_eventually 180 "demo Synced + Healthy" argo_app_ok demo
check_eventually 60 "rollout complete, every demo pod on an image tag that exists" eval 'rolled_out && tags_exist'
check_eventually 60 "demo.lab greets with Bonjour" bonjour
check "the fix is in Git: app.greeting: Bonjour in envs/demo/values.yaml" git_values
verdict
