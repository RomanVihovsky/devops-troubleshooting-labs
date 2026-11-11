# Y10 - encrypted_regex that misses stringData

**Root cause**: a commit "tightened" `.sops.yaml` to `encrypted_regex: ^data$`. SOPS encrypts only the values
under keys that match the regex. The new Secret uses `stringData`, so SOPS wrote its `sops:` metadata block
(the file *looks* encrypted) and left the password in plain text. It went into Git and is in the history for
good.

**Diagnosis**
```
head -12 secrets/new-service.enc.yaml              # password: leak-...   (no ENC[...])
git log -p -2 -- .sops.yaml                        # ^(data|stringData)$ -> ^data$
```

**Fix**
1. The rule back to `encrypted_regex: ^(data|stringData)$`. Every Kubernetes Secret has one of the two.
2. **Rotate**: a new password in the file, `sops -e -i`, commit, push. Don't rewrite history: forks and clones
   already have it, so the old value must become worthless instead.
3. Roll it out: `sops -d secrets/new-service.enc.yaml | kubectl apply -f -`, then restart Redis.

**Interview notes**
- A leaked secret is **rotated**, always. History rewriting (filter-repo/BFG) is optional cleanup, never the
  fix.
- Guardrails: a pre-commit hook / CI step that fails if a `*.enc.yaml` has a non-`ENC[` value under
  `data`/`stringData` (or a secret scanner such as gitleaks/trufflehog on every push);
  `unencrypted_regex`/`encrypted_regex` reviewed like code.
- `sops -e` succeeding means nothing about *what* it encrypted. Check the output.
- With Argo CD, SOPS needs a plugin (KSOPS or a CMP) holding a decryption key in the cluster. Many teams
  prefer ESO (no secret material in Git at all).
