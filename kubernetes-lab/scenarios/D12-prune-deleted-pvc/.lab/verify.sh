pv=$(recall d12_pv)
same_pv() { [ "$(kx -n notes get pvc notes -o jsonpath='{.status.phase} {.spec.volumeName}' 2>/dev/null)" = "Bound $pv" ]; }
data_back() { [ "$(kx -n notes exec deploy/notes -- labapp get http://localhost:8080/kv/meeting-2026-11 2>/dev/null)" = "$(recall d12_value)" ]; }
in_git() {
  gx "/repos/lab/gitops/raw/envs/notes/values.yaml?ref=main" 2>/dev/null | python3 -c '
import sys, yaml
p = (yaml.safe_load(sys.stdin) or {}).get("persistence") or {}
a = str((p.get("annotations") or {}).get("argocd.argoproj.io/sync-options", ""))
sys.exit(0 if p.get("enabled") is True and "Prune=false" in a else 1)'
}
live_annot() { kx -n notes get pvc notes -o jsonpath='{.metadata.annotations.argocd\.argoproj\.io/sync-options}' 2>/dev/null | grep -q 'Prune=false'; }
check_eventually 120 "PVC notes is Bound to the original volume $pv" same_pv
check_eventually 120 "notes serves its old data" data_back
check "Git: persistence enabled, PVC annotated Prune=false" in_git
check "the live PVC carries Prune=false" live_annot
check_eventually 180 "app notes is Synced and Healthy" argo_app_ok notes
verdict
