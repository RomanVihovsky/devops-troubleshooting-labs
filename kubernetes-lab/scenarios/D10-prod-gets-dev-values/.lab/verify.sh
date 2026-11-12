cm_level() { kx -n "$1" get configmap web -o jsonpath='{.data.LOG_LEVEL}' 2>/dev/null; }
raw() { gx "/repos/lab/gitops/raw/$1?ref=main"; }
prod_file_kept() { raw envs/web-prod/values.yaml | python3 -c 'import sys, yaml
v = yaml.safe_load(sys.stdin) or {}
sys.exit(0 if v.get("replicaCount") == 3 and (v.get("app") or {}).get("logLevel") == "info" else 1)'; }
dev_file_kept() { raw envs/web-dev/values.yaml | python3 -c 'import sys, yaml
v = yaml.safe_load(sys.stdin) or {}
sys.exit(0 if v.get("replicaCount") == 1 and (v.get("app") or {}).get("logLevel") == "debug" else 1)'; }
check_eventually 180 "web-prod Synced + Healthy" argo_app_ok web-prod
check_eventually 60 "web-dev Synced + Healthy" argo_app_ok web-dev
check_eventually 180 "web-prod: 3 Ready pods" deploy_ready web-prod web 3
check_eventually 60 "web-prod: LOG_LEVEL=info" test "$(cm_level web-prod)" = info
check_eventually 60 "web-dev: 1 Ready pod" deploy_ready web-dev web 1
check "web-dev: LOG_LEVEL=debug" test "$(cm_level web-dev)" = debug
check "Git: envs/web-prod/values.yaml still says 3 replicas / info" prod_file_kept
check "Git: envs/web-dev/values.yaml still says 1 replica / debug" dev_file_kept
verdict
