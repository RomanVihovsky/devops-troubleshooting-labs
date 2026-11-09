# T14 - solution and takeaways

```
cat > secrets/t14.yaml <<EOF            # Secret t14-db, stringData.password: <password.txt>
...
EOF
sops -e -i secrets/t14.yaml             # before git add!
# .sops.yaml:  age: <lab key>,<team key>
sops updatekeys secrets/t14.yaml
git add .sops.yaml secrets/t14.yaml && git commit -m ... && git push
```

**Takeaways**
- SOPS encrypts *values* (here only under `data`/`stringData`) with one data key, and wraps that data key
  once per recipient (age, PGP, KMS, Vault transit). Adding/removing a recipient = `updatekeys`, no
  re-encryption of the values; removing a person who had the key also needs a **value** rotation.
- The structure stays readable: reviews show *which* key changed, not the secret. The MAC protects the
  whole file against tampering.
- Plaintext pushed once is compromised - rotate it; history rewrites don't reach every clone.
- Argo CD can't read SOPS files by itself: a CMP/KSOPS plugin, helm-secrets or decrypting in CI is
  needed. Sealed Secrets and ESO avoid giving the cluster a decryption key for Git (T12, T13).
