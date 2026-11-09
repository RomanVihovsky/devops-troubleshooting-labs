seal() { kx -n t12 create secret generic "$1" --from-literal="$2" --dry-run=client -o yaml | kubeseal --format yaml --scope "$3"; }
seal api-key key=K3y-t12 strict > api-key.sealed.yaml
seal shared-config mode=blue namespace-wide > shared-config.sealed.yaml
seal banner text=hello cluster-wide > banner.sealed.yaml
kx apply -f api-key.sealed.yaml -f shared-config.sealed.yaml -f banner.sealed.yaml >/dev/null
kx -n kube-system get secret -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml > sealing-key.backup.yaml
restart_controller() {
  kx -n kube-system delete pod -l app.kubernetes.io/name=sealed-secrets --wait=true >/dev/null
  kx -n kube-system rollout status deploy/sealed-secrets-controller --timeout=120s >/dev/null
}
kx -n kube-system delete secret -l sealedsecrets.bitnami.com/sealed-secrets-key >/dev/null       # the drill
restart_controller
newkey() { kx -n kube-system get secret -l sealedsecrets.bitnami.com/sealed-secrets-key --no-headers | grep -q .; }
retry 60 newkey
kx apply -f legacy.yaml >/dev/null
python3 - <<'PY'   # restore: the backed-up key objects, without resourceVersion/uid
import yaml
d = yaml.safe_load(open("sealing-key.backup.yaml"))
for o in d["items"]:
    for k in ("resourceVersion", "uid", "creationTimestamp", "managedFields"): o["metadata"].pop(k, None)
yaml.safe_dump(d, open("sealing-key.restore.yaml", "w"))
PY
kx apply -f sealing-key.restore.yaml >/dev/null
restart_controller
legacy() { [ "$(kx -n t12 get secret legacy -o jsonpath='{.data.password}' 2>/dev/null | base64 -d)" = 0ld-but-g0ld ]; }
retry 120 legacy || kx -n t12 annotate sealedsecret legacy lab/retry="$(date +%s)" --overwrite >/dev/null
retry 60 legacy || true
