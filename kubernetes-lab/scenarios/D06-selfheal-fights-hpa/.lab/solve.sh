W="$LAB_DIR/workspace/gitops"
git -C "$W" pull -q
cat >> "$W/envs/demo/values.yaml" <<'YML'
autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 6
YML
git -C "$W" commit -qam "demo: the HPA lives in the chart, Git no longer pins replicas (INC-2318)"
git -C "$W" push -q origin main 2>/dev/null
argo_refresh demo
retry 180 argo_app_ok demo || true
