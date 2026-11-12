## Hint 1
`git -C workspace/gitops log --oneline -3 -- .sops.yaml secrets/` and `head -20 secrets/new-service.enc.yaml`.
Which keys does SOPS encrypt? (`encrypted_regex` in `.sops.yaml`.)

## Hint 2
`encrypted_regex: ^data$` matches the key `data`, not `stringData` - the file uses `stringData`, so SOPS added
its metadata and left the values alone. The old commit stays in history: the password must be rotated.

## Hint 3
Fix the rule (`^(data|stringData)$`), write a **new** password into the file, `sops -e -i` it, commit + push.
Then `sops -d secrets/new-service.enc.yaml | kubectl apply -f -` and `kubectl -n newsvc rollout restart deploy/redis`.
