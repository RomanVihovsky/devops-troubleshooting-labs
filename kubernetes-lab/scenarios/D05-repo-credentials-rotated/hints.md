## Hint 1
`kubectl -n argocd get applications` and `argocd app get demo`: read the condition message. Where does Argo CD
keep the credentials of a repository? `kubectl -n argocd get secrets -l argocd.argoproj.io/secret-type=repository`.

## Hint 2
The repo Secret still holds the old password. The new one: `bao kv get -mount=secret ci/gitea-argocd`
(`eval "$(./lab env)"` sets up the bao CLI).

## Hint 3
`kubectl -n argocd patch secret repo-gitops --type merge -p '{"stringData":{"password":"<new>"}}'` (or
`argocd repo add http://git.lab:3000/lab/gitops.git --username argocd --password <new> --upsert`), then
`argocd app get demo --hard-refresh`.
