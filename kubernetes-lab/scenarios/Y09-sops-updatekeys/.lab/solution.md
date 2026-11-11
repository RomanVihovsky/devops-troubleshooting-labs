# Y09 - sops updatekeys after adding a recipient

**Root cause**: SOPS encrypts a file's values with a random **data key** and stores that data key once per
recipient (here: age), wrapped with each recipient's public key, in the file's `sops:` section. `.sops.yaml`
decides the recipients **when a file is encrypted**. Adding alice to `.sops.yaml` changed nothing in files
that already existed: `prod.enc.yaml` still carried only the team's wrapped data key.

**Diagnosis**
```
grep -A3 'age:' secrets/prod.enc.yaml          # one recipient: the team key
cat .sops.yaml                                 # two recipients
SOPS_AGE_KEY_FILE=alice.key sops -d secrets/prod.enc.yaml   # no identity matched
```

**Fix** (with a key that can decrypt today):
```
cd workspace/gitops
sops updatekeys -y secrets/prod.enc.yaml       # re-wrap the data key for .sops.yaml's recipients
git commit -am "re-wrap for alice" && git push
```
For many files: `find secrets -name '*.enc.yaml' -exec sops updatekeys -y {} \;`.

**Interview notes**
- `updatekeys` re-wraps the data key; it does **not** change the data key or the values. Removing a person
  needs `sops rotate` (a new data key) *and* rotating the secrets themselves: they could read them before.
- Onboarding/offboarding = `.sops.yaml` + `updatekeys` (or `rotate`) over every file, in one reviewed
  commit. CI can check that every file's recipients match the rules.
- Prefer group keys (a team age key, KMS/Vault transit) over many personal keys, then onboarding is
  granting access to the KMS key, not re-encrypting files.
- SOPS vs Sealed Secrets vs ESO: SOPS keeps ciphertext in Git and decrypts with the person's/CI's key;
  Sealed Secrets decrypts in-cluster with one controller key; ESO keeps no secret in Git at all.
