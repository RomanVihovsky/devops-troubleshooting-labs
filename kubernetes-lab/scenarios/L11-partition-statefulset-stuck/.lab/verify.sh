db_elsewhere() {
  [ "$(kx -n inventory get pod db-0 -o jsonpath='{.spec.nodeName} {.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)" != "k8s-w3 True" ] \
    && [ "$(kx -n inventory get pod db-0 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)" = True ] \
    && [ -z "$(kx -n inventory get pod db-0 -o jsonpath='{.metadata.deletionTimestamp}' 2>/dev/null)" ]
}
data_ok() { [ "$(kx -n inventory exec db-0 -- cat /data/orders.db 2>/dev/null)" = "order-42 shipped" ]; }
same_pvc() { [ "$(kx -n inventory get pvc data-db-0 -o jsonpath='{.metadata.uid}' 2>/dev/null)" = "$(recall l11_pvc)" ]; }
one_replica() { [ "$(kx -n inventory get sts db -o jsonpath='{.spec.replicas}' 2>/dev/null)" = 1 ]; }
web_ok() {
  [ "$(kx -n inventory get pods -l app=web -o json 2>/dev/null | jq '[.items[] | select(.spec.nodeName != "k8s-w3" and .metadata.deletionTimestamp == null
      and any(.status.conditions[]?; .type == "Ready" and .status == "True"))] | length')" -ge 2 ]
}
check_eventually 120 "db-0 Ready on another node" db_elsewhere
check "db-0 kept its data (/data/orders.db)" data_ok
check "same PVC data-db-0 (not re-created)" same_pvc
check "StatefulSet db still has 1 replica" one_replica
check_eventually 60 "web: 2 ready pods away from k8s-w3" web_ok
verdict
