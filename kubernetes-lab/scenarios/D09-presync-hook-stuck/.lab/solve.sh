W="$LAB_DIR/workspace/gitops"
git -C "$W" pull -q
python3 - "$W/envs/billing/values.yaml" <<'PY'
import sys, yaml
p = sys.argv[1]; v = yaml.safe_load(open(p))
pre = {
    "argocd.argoproj.io/hook": "PreSync",
    "argocd.argoproj.io/hook-delete-policy": "BeforeHookCreation",
    "argocd.argoproj.io/sync-wave": "-1",
}
v["secrets"]["sealedSecret"]["annotations"] = dict(pre)
v.setdefault("config", {})["annotations"] = dict(pre)
open(p, "w").write(yaml.safe_dump(v, sort_keys=False))
PY
git -C "$W" commit -qam "billing: the migration's ConfigMap and SealedSecret are PreSync hooks before it (INC-2340)"
git -C "$W" push -q origin main 2>/dev/null
# argocd app terminate-op = set the running operation's phase to Terminating (the CRD has no status subresource)
kx -n argocd patch application billing --type merge -p '{"status":{"operationState":{"phase":"Terminating"}}}' >/dev/null
not_running() { [ "$(kx -n argocd get application billing -o jsonpath='{.status.operationState.phase}')" != Running ]; }
retry 120 not_running || true
argo_refresh billing
argo_sync billing
retry 240 argo_app_ok billing || true
