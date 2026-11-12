new=$(bx kv get -mount=secret -field=password ci/gitea-argocd 2>/dev/null)
old=$(cat "$GITEA_DIR/argocd-password")
git_ok() { git ls-remote "http://$1:$2@192.168.56.20:3000/lab/gitops.git" HEAD >/dev/null 2>&1; }
old_rejected() { ! git_ok argocd "$old"; }
# every repository Secret for lab/gitops (repo-gitops, or one made by "argocd repo add") - as "user:password" lines
repo_creds() {
  kx -n argocd get secrets -l argocd.argoproj.io/secret-type=repository -o json \
    | jq -r --arg u "$GITOPS_REPO" '.items[] | select((.data.url // "" | @base64d) == $u)
        | "\(.data.username // "" | @base64d):\(.data.password // "" | @base64d)"'
}
creds_right() { [ -n "$(repo_creds)" ] && ! repo_creds | grep -vqxF "argocd:$new"; }
no_cmp_error() { ! kx -n argocd get application "$1" -o json | jq -e '[.status.conditions[]? | select(.type == "ComparisonError")] | length > 0' >/dev/null; }
app_good() { argo_app_ok "$1" && no_cmp_error "$1"; }
for a in lab-apps demo shop; do argo_refresh "$a"; done
for a in lab-apps demo shop; do check_eventually 150 "$a Synced + Healthy, no ComparisonError (after a hard refresh)" app_good "$a"; done
check "the repo credentials are user argocd with the new password (only those)" creds_right
check "Gitea accepts argocd with the new password" git_ok argocd "$new"
check "Gitea rejects the old password (the rotation stays)" old_rejected
verdict
