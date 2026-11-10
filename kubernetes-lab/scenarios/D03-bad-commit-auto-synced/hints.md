## Hint 1
`kubectl -n demo get pods` and `kubectl -n demo logs <pod> --previous`: why does the new version exit?
`git -C workspace/gitops log --oneline -5` - which commit did it?

## Hint 2
Rolling back in Argo CD (`argocd app rollback`) needs auto-sync *off*, and the next sync puts the RC back.
`kubectl rollout undo` is reverted by self-heal. With GitOps the rollback is a **commit**.

## Hint 3
`git revert --no-edit <rc commit>` in `workspace/gitops`, push, `argocd app get demo --refresh`. A revert
keeps the RC in the history - re-applying it later is a revert of the revert.
