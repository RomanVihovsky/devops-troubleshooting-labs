W="$LAB_DIR/workspace/gitops"
git -C "$W" pull -q
rc=$(git -C "$W" log --format=%H --grep=2.0.0-rc1 -1)
git -C "$W" revert --no-edit "$rc" >/dev/null
git -C "$W" push -q origin main 2>/dev/null
argo_refresh demo
retry 240 argo_app_ok demo || true
