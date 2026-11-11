new=$(bx kv get -mount=secret -field=password ci/gitea-argocd)
kx -n argocd patch secret repo-gitops --type merge -p "{\"stringData\":{\"password\":\"$new\"}}" >/dev/null
for a in lab-apps demo shop; do argo_refresh "$a"; done
retry 180 argo_app_ok demo || true
