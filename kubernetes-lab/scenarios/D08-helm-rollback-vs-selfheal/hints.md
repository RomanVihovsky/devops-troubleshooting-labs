## Hint 1
`argocd app history ledger` and `argocd app get ledger`: who decides what runs in `ledger` now? What did
`helm rollback` change, and what did Argo CD do a minute later?

## Hint 2
Argo CD renders the chart itself (`helm template`) and applies the result; it never uses Helm's release
records. A `helm rollback` is drift, and self-heal reverts it. The rollback has to happen in Git:
`git -C workspace/gitops log --oneline -- envs/ledger`.

## Hint 3
`git revert` the 1.5 commit, push, `argocd app get ledger --refresh`. Then delete the stale release records
so `helm list`/`helm rollback` stop pretending: `kubectl -n ledger delete secret -l owner=helm,name=ledger`.
