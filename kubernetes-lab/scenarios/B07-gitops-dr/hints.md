## Hint 1
Find the dependency order before fixing anything: which piece needs which? (Argo CD needs repo credentials, which
live in OpenBao; ExternalSecrets need OpenBao; SealedSecrets need the key; every app needs the root app.)
`argocd app list`, `kubectl get sealedsecrets,externalsecrets -A`, `bao status`.

## Hint 2
OpenBao: the static seal key in `/etc/openbao/` was replaced - restore it from the backup tarball on gw and restart
the service (Y06). Then read the repo password: `bao kv get -mount=secret ci/gitea-argocd`. The root app: compare its
`targetRevision` with the branches in Gitea.

## Hint 3
Repo Secret `argocd/repo-gitops` (label `argocd.argoproj.io/secret-type=repository`, `url`, `username`, `password`,
`type: git`); root app `targetRevision: main`; `kubectl apply -f .state/sealed-secrets-key.yaml` + restart the
controller (Y02); then refresh **and sync** the apps (an automated sync that failed while the repo was unreachable is not retried
for the same revision) and force-sync the ExternalSecrets.
