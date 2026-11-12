KJ="$PWD/jane.kubeconfig"
jk() { kubectl --kubeconfig "$KJ" --request-timeout=10s "$@"; }
csr_ok() {
  [ "$(kx get csr t07-jane -o jsonpath='{.status.conditions[?(@.type=="Approved")].status}' 2>/dev/null)" = True ] \
    && [ -n "$(kx get csr t07-jane -o jsonpath='{.status.certificate}' 2>/dev/null)" ]
}
jane_is_jane() {
  local w; w=$(jk auth whoami -o json 2>/dev/null) || return 1
  jq -e '.status.userInfo.username == "jane" and (.status.userInfo.groups | index("t07-devs"))' <<<"$w" >/dev/null
}
jcan() { [ "$(jk auth can-i "$@" 2>/dev/null)" = yes ]; }
jane_reads_logs() { jk -n t07 logs app --tail=1 >/dev/null; }
group_binding() {
  kx -n t07 get rolebindings -o json | jq -e '[.items[].subjects[]? | select(.kind == "Group" and .name == "t07-devs")] | length > 0' >/dev/null \
    && ! kx -n t07 get rolebindings -o json | jq -e '[.items[].subjects[]? | select(.kind == "User" and .name == "jane")] | length > 0' >/dev/null
}
CA=$(mktemp); kx config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d > "$CA"
EMPTY=$(mktemp); printf 'apiVersion: v1\nkind: Config\n' > "$EMPTY"
ci_is_ci() {
  [ -s ci.token ] || return 1
  [ "$(kubectl --kubeconfig "$EMPTY" --server=https://192.168.56.20:6443 --certificate-authority="$CA" \
       --token="$(cat ci.token)" --request-timeout=10s auth whoami -o jsonpath='{.status.userInfo.username}' 2>/dev/null)" = system:serviceaccount:t07:ci ]
}
SA=system:serviceaccount:t07:ci
check "CSR t07-jane approved and issued" csr_ok
check "jane.kubeconfig authenticates as jane, group t07-devs" jane_is_jane
check "jane: list pods in t07" jcan list pods -n t07
check "jane: read pod logs in t07" jane_reads_logs
check "jane: NOT delete pods in t07" not jcan delete pods -n t07
check "jane: NOT read secrets in t07" not jcan get secrets -n t07
check "jane: NOT list pods in default" not jcan list pods -n default
check "the RoleBinding names the group t07-devs (not the user jane)" group_binding
check "ci.token authenticates as $SA" ci_is_ci
check "ci: create deployments in t07" can_i "$SA" create deployments -n t07
check "ci: NOT create deployments in default" not can_i "$SA" create deployments -n default
check "ci: NOT read secrets in t07" not can_i "$SA" get secrets -n t07
rm -f "$CA" "$EMPTY"
verdict
