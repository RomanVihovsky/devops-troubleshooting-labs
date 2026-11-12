items_ok() { curl -s --max-time 5 -H 'Host: shopfront.lab' http://192.168.56.200/api/items | jq -e '(.items // .) | length > 0' >/dev/null 2>&1; }
no_base() { ! kx -n api-gw get deploy items -o json | jq -e '[.spec.template.spec.containers[].env[]? | select(.name == "BASE_PATH")] | length > 0' >/dev/null; }
check_eventually 60 "shopfront.lab/api/items answers with the item list" items_ok
check "the app has no BASE_PATH" no_base
verdict
