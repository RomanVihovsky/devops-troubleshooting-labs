# D05: the Gitea account "argocd" gets a new password (published in OpenBao); Argo CD's repo Secret keeps the old one
new=$(rand)
bx kv put -mount=secret ci/gitea-argocd username=argocd password="$new" >/dev/null
nx k8s-gw "runuser -u git -- gitea --config /etc/gitea/app.ini admin user change-password --username argocd \
  --password '$new' --must-change-password=false" </dev/null >/dev/null
# the repo-server serves cached manifests until it has to fetch again: a hard refresh of every app
for a in lab-apps demo shop; do argo_refresh "$a"; done
denied() { kx -n argocd get application demo -o json | jq -e '[.status.conditions[]? | select(.message | test("authentication|not accessible"; "i"))] | length > 0' >/dev/null; }
retry 180 denied || die "Argo CD can still read the repo"
