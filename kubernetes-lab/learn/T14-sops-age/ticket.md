# T14 · SOPS + age: encrypt in Git, a second recipient, updatekeys, no plaintext in history
**Learn** · keep secrets in the repo, encrypted per value, readable by exactly the right keys · ~30 min

`workspace/gitops/.sops.yaml` already encrypts `secrets/*.yaml` for the lab's age key (`./lab env` sets
`SOPS_AGE_KEY_FILE`). The payments team needs a database Secret in Git, and the **team's** age key
(`workspace/T14/team.age.pub`) must be able to decrypt it too.

1. Write `secrets/t14.yaml`: a Kubernetes Secret `t14-db` with `stringData.password` = the value in
   `workspace/T14/password.txt`. **Encrypt it before it ever gets committed** (`sops -e -i`). Look at the
   result: what is encrypted, what isn't?
2. Add the team's public key to the `secrets/` rule in `.sops.yaml` and re-wrap the data key of the existing
   file with `sops updatekeys`.
3. Commit and push. `git log -p` must never show the password.

**Test**: on main, `secrets/t14.yaml` is SOPS-encrypted for 2 age recipients and decrypts (with the lab key
and with the team key) to `t14-db` with the right password; `.sops.yaml` lists both keys; the plaintext
password appears nowhere in the Git history.
