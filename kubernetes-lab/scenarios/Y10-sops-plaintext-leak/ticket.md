# Secret scanner: plaintext password in secrets/new-service.enc.yaml
**SEC-118** · P1 · Reporter: security

Our scanner flagged `secrets/new-service.enc.yaml` in `lab/gitops`: it has a `sops:` block, yet the Redis
password is readable in plain text. That password is live: `newsvc`'s Redis uses it (the Secret was applied from
that file with `sops -d ... | kubectl apply -f -`, see `workspace/Y10/README.md`). Fix the encryption so it
can't happen again, and make the leaked password worthless. Don't rewrite Git history - assume it's cloned
everywhere already.

**Test**: at `main` the file holds no plaintext value (every `data`/`stringData` value is `ENC[...]`) and
decrypts with the team key; `.sops.yaml`'s rule covers both `data` and `stringData`; the password in the file is
a new one; Redis in `newsvc` accepts the new password and rejects the leaked one.
