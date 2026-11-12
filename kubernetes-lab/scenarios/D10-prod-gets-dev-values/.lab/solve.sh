W="$LAB_DIR/workspace/gitops"
git -C "$W" pull -q
sed -i 's|valueFiles: \[../../envs/web-prod/values.yaml, ../../envs/web-dev/values.yaml\]|valueFiles: [../../envs/web-prod/values.yaml]|' "$W/apps/web-prod.yaml"
git -C "$W" commit -qam "web-prod: render prod's values only (INC-2346)"
git -C "$W" push -q origin main 2>/dev/null
argo_refresh lab-apps; argo_refresh web-prod
retry 240 argo_app_ok web-prod || true
