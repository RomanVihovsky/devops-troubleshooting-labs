raw() { gx "/repos/lab/gitops/raw/$1?ref=main"; }
no_15() { ! raw envs/ledger/values.yaml | grep -qE 'tag: *"?1\.5'; }
autosync() { raw apps/ledger.yaml | python3 -c 'import sys, yaml
s = yaml.safe_load(sys.stdin)["spec"].get("syncPolicy") or {}
a = s.get("automated") or {}
sys.exit(0 if a.get("selfHeal") is True and a.get("prune") is True else 1)'; }
quiet() {
  local since; since=$(date -u -d "-$2 seconds" +%FT%TZ)
  argo_app_ok "$1" && [ "$(kx -n argocd get application "$1" -o jsonpath='{.status.operationState.startedAt}')" \< "$since" ]
}
no_release() { [ -z "$(kx -n ledger get secrets -l owner=helm,name=ledger -o name 2>/dev/null)" ] \
               && ! kx -n ledger get secrets -o name | grep -q 'sh.helm.release.v1.ledger'; }
check_eventually 240 "ledger answers 200 inside the cluster" http_ok ledger http://ledger.ledger.svc:8080/
check_eventually 120 "ledger pods stable 30 s" stable_for 30 ledger app.kubernetes.io/instance=ledger
check_eventually 180 "ledger Synced + Healthy, no sync operation for 60 s" quiet ledger 60
check "main no longer deploys 1.5 for ledger" no_15
check "auto-sync with prune + self-heal still on for ledger (in Git)" autosync
check "no Helm release records for ledger left in the namespace" no_release
verdict
