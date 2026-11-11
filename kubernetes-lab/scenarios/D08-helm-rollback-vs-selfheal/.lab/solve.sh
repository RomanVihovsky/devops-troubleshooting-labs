W="$LAB_DIR/workspace/gitops"
git -C "$W" pull -q
c=$(git -C "$W" log --format=%H --grep='ledger 1.5' -1)
git -C "$W" revert --no-edit "$c" >/dev/null
git -C "$W" push -q origin main 2>/dev/null
argo_refresh ledger
kx -n ledger delete secret -l owner=helm,name=ledger >/dev/null
retry 240 argo_app_ok ledger || true
