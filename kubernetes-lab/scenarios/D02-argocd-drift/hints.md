## Hint 1
In Argo CD, open **demo → App diff** (or `argocd app diff demo`, `kubectl -n argocd get app demo -o yaml`).
What differs between Git and the cluster, and why does Argo CD not fix it by itself?

## Hint 2
`syncPolicy.automated.selfHeal: false` (the freeze, see `git log` in `workspace/gitops`): automated sync
only reacts to **Git** changes, it doesn't revert live edits. Someone has to sync - or change Git.

## Hint 3
Git is right and the freeze must stay, so don't touch Git: sync the app from Git. UI: **Sync** →
Synchronize. CLI: `argocd app sync demo` (after `argocd login 192.168.56.201 --plaintext`). That brings the
replicas back to 2 - but check the env afterwards (`kubectl -n demo get deploy demo -o yaml`): `GREETING`
is not in Git, so the sync's three-way merge keeps it and Argo CD still says *Synced*. Remove it:
`kubectl -n demo set env deploy/demo GREETING-` (or a sync with the *Replace* option).
