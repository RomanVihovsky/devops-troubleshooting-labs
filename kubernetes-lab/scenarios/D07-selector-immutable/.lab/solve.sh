W="$LAB_DIR/workspace/gitops"
git -C "$W" pull -q
c=$(git -C "$W" log --format=%H --grep='select pods by version' -1)
git -C "$W" revert --no-edit "$c" >/dev/null
git -C "$W" push -q origin main 2>/dev/null
for a in demo shop; do argo_refresh "$a"; done
retry 240 argo_app_ok demo || true
retry 120 argo_app_ok shop || true
