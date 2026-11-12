deployed() { helm status web -n importx -o json 2>/dev/null | jq -e '.info.status == "deployed"' >/dev/null; }
same_svc() { [ "$(kx -n importx get svc web -o jsonpath='{.metadata.uid}')" = "$(recall o05_uid)" ]; }
owned() { [ "$(kx -n importx get svc web -o jsonpath='{.metadata.annotations.meta\.helm\.sh/release-name}')" = web ]; }
check "release web deployed" deployed
check "Service web is the same object as before" same_svc
check "...and belongs to release web" owned
check_eventually 120 "web: 2 Ready pods" deploy_ready importx web 2
check_eventually 30 "Service web has endpoints" has_endpoints importx web
verdict
