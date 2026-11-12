demo_up() { [ "$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 -H 'Host: demo.lab' -H "Authorization: Bearer $(cat "$STATE_DIR/demo-token")" http://192.168.56.200/)" = 200 ]; }
W=$(mktemp -d)
git clone -q "http://lab:$(cat "$GITEA_DIR/token")@192.168.56.20:3000/lab/gitops.git" "$W" 2>/dev/null
# the chart at main, rendered: the Deployment selector's keys
# deploy_field <python expr on the Deployment d>: from the chart at main, rendered
deploy_field() {
  helm template d "$W/charts/labapp" 2>/dev/null | python3 -c 'import sys, yaml
d = [o for o in yaml.safe_load_all(sys.stdin) if o and o.get("kind") == "Deployment"][0]
print(eval(sys.argv[1]))' "$1"
}
sel_keys() { deploy_field '",".join(sorted(d["spec"]["selector"]["matchLabels"]))'; }
pod_version() { [ "$(deploy_field '"app.kubernetes.io/version" in d["spec"]["template"]["metadata"]["labels"]')" = True ]; }
synced_ok() { argo_app_ok "$1" && [ "$(kx -n argocd get application "$1" -o jsonpath='{.status.operationState.phase}')" = Succeeded ]; }
no_replace() { ! grep -rqs 'Replace=true' "$W/apps" "$W/charts" "$W/envs" && ! kx -n argocd get applications -o yaml | grep -q 'Replace=true'; }
check_eventually 60 "demo.lab answers 200 (with the token)" demo_up
check_eventually 120 "shop.lab end to end" shop_ok
check_eventually 180 "demo Synced + Healthy, last sync Succeeded" synced_ok demo
check_eventually 120 "shop Synced + Healthy, last sync Succeeded" synced_ok shop
check "main: the Deployment selector is name + instance only" test "$(sel_keys)" = "app.kubernetes.io/instance,app.kubernetes.io/name"
check "main: pods still carry app.kubernetes.io/version" pod_version
check "no Replace=true sync option (in Git or on the apps)" no_replace
rm -rf "$W"
verdict
