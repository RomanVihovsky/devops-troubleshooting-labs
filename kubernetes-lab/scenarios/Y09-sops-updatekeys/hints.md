## Hint 1
`git -C workspace/gitops show --stat HEAD~1 HEAD` - what did the onboarding commit change? Then look at the
`sops:` section at the end of `secrets/prod.enc.yaml`: which age recipients can open it?

## Hint 2
`.sops.yaml` is only read when a file is **encrypted** (or its keys are updated). Files encrypted before the
change still carry a data key wrapped for the old recipients only.

## Hint 3
`cd workspace/gitops && sops updatekeys -y secrets/prod.enc.yaml` (it re-wraps the data key for the
recipients `.sops.yaml` now lists; it needs a key that can decrypt today: the team key). Commit, push.
