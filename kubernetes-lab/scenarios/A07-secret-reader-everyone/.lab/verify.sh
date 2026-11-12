no_group_grant() { ! kx get clusterrolebindings -o json | jq -e '[.items[] | select(.subjects[]? | .kind == "Group" and (.name == "system:authenticated" or .name == "system:serviceaccounts"))
  | .roleRef.name] | map(select(. == "secret-reader" or . == "cluster-admin" or . == "admin" or . == "edit")) | length > 0' >/dev/null; }
check "backup/backup-agent can list Secrets in all namespaces" can_i system:serviceaccount:backup:backup-agent list secrets -A
cannot() { ! can_i "$@"; }
check "bob can't list Secrets cluster-wide" cannot bob list secrets -A
check "bob can't read Secrets in shop" cannot bob get secrets -n shop
check "default/default can't list Secrets cluster-wide" cannot system:serviceaccount:default:default list secrets -A
check "no cluster-wide Secret access for system:authenticated / system:serviceaccounts" no_group_grant
verdict
