d=stacks/config-bundle
lock=$WS/$d/.terraform.lock.hcl
hashes_for() {   # hashes_for <provider> -> number of h1 hashes recorded
  awk -v p="registry.terraform.io/hashicorp/$1" '$0 ~ "provider \""p"\"" {on=1} on && /h1:/ {n++} on && /^}/ {on=0} END {print n+0}' "$lock"
}
pinned() { grep -A1 'hashicorp/random"' "$lock" | grep -q '"3.9.1"' && grep -A1 'hashicorp/local"' "$lock" | grep -q '"2.9.1"'; }
committed() { git -C "$WS" diff --quiet HEAD -- "$d/.terraform.lock.hcl"; }
check "CI init + plan of stacks/config-bundle: no changes" plan_clean $d
check "lock file has 2+ platform hashes for random and local" eval '[ "$(hashes_for random)" -ge 2 ] && [ "$(hashes_for local)" -ge 2 ]'
check "versions unchanged: random 3.9.1, local 2.9.1" pinned
check "lock file committed" committed
verdict
