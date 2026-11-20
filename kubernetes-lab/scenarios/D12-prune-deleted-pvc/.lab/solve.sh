pv=$(recall d12_pv)
kx patch pv "$pv" --type=json -p '[{"op":"replace","path":"/spec/claimRef","value":{"namespace":"notes","name":"notes"}}]' >/dev/null
W="$LAB_DIR/workspace/gitops"
git -C "$W" pull -q
python3 - "$W/envs/notes/values.yaml" <<'PY'
import sys, yaml
p = sys.argv[1]; v = yaml.safe_load(open(p))
v["persistence"]["enabled"] = True
v["persistence"]["annotations"] = {"argocd.argoproj.io/sync-options": "Prune=false"}
open(p, "w").write(yaml.safe_dump(v, sort_keys=False))
PY
git -C "$W" commit -qam "notes: the PVC is back, and Argo CD must never prune it (INC-2734)"
git -C "$W" push -q origin main 2>/dev/null
argo_refresh notes
bound() { [ "$(kx -n notes get pvc notes -o jsonpath='{.spec.volumeName}' 2>/dev/null)" = "$pv" ]; }
retry 180 bound || true
retry 180 argo_app_ok notes || true
retry 120 deploy_ready notes notes || true
