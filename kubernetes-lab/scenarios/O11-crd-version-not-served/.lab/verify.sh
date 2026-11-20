names() { kx get --raw "/apis/example.lab/$1/namespaces/factory/widgets" 2>/dev/null | jq -r '[.items[] | "\(.metadata.name)=\(.spec.color)/\(.spec.size)"] | sort | join(" ")'; }
want="bolt=blue/1 gear=red/3 spring=green/7"
both() { [ "$(names v1)" = "$want" ] && [ "$(names v2)" = "$want" ]; }
storage_v2() { [ "$(kx get crd widgets.example.lab -o jsonpath='{.spec.versions[?(@.storage==true)].name}' 2>/dev/null)" = v2 ]; }
stored_list() { [ "$(kx get crd widgets.example.lab -o jsonpath='{.status.storedVersions}' 2>/dev/null)" = '["v2"]' ]; }
in_etcd_v2() {
  local w raw
  for w in bolt gear spring; do
    raw=$(nx "$CP" "etcdctl $ETCD_FLAGS get /registry/example.lab/widgets/factory/$w --print-value-only 2>/dev/null" </dev/null) || return 1
    grep -q '"apiVersion":"example.lab/v2"' <<<"$raw" || return 1
  done
}
check_eventually 90 "widget-reporter is Ready (v1 answers)" deploy_ready factory widget-reporter 1
check "all 3 widgets read the same as v1 and as v2" both
check "v2 is the storage version" storage_v2
check "every widget is stored as v2 in etcd" in_etcd_v2
check "status.storedVersions is [v2]" stored_list
verdict
