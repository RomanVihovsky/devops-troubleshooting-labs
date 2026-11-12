still_there() { gx "/repos/lab/gitops/raw/apps/team/metrics.yaml?ref=main" | grep -q 'name: metrics'; }
check_eventually 180 "Application metrics exists" kx -n argocd get application metrics
check_eventually 180 "metrics Synced + Healthy" argo_app_ok metrics
check_eventually 120 "metrics pods Ready" deploy_ready metrics metrics
check_eventually 60 "lab-apps Synced + Healthy" argo_app_ok lab-apps
check "apps/team/metrics.yaml is still in Git" still_there
verdict
