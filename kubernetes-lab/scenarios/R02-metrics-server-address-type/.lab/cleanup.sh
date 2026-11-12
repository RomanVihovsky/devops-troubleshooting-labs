# metrics-server is a cluster add-on (helm): back to its golden values
helm_up metrics-server kube-system "$(gw_file "metrics-server-$METRICS_SERVER_CHART_VERSION.tgz")" "$ADDONS/metrics-server-values.yaml" >/dev/null 2>&1 \
  || warn "R02: metrics-server not restored"
wait_rollout kube-system deploy/metrics-server 120 || true
