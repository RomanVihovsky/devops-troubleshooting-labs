# C03 - base64 twice

**Root cause**: the Secret file had `data: {password: <base64 of base64 of the password>}`. The API stores
`data` values as bytes and decodes the base64 **once**. The container got the base64 text instead of the
password, and Redis answered WRONGPASS. `kubectl get secret -o yaml` shows `data` base64-encoded, so the
manifest and the object looked the same, which hid the mistake.

**Diagnosis**
```
kubectl -n cart logs deploy/cart | grep -m1 WRONGPASS
kubectl -n cart get secret cart-redis -o jsonpath='{.data.password}' | base64 -d; echo    # looks like base64
kubectl -n cart get secret redis-auth -o jsonpath='{.data.password}' | base64 -d; echo
```

**Fix**: `stringData: {password: <plain>}` (the API encodes it) or a single `base64 -w0`; then restart the
pods, because env values from Secrets are read at start.

**Interview notes**
- `data`: base64 in the manifest. `stringData`: plain text, merged into `data` on write (write-only: you
  never read it back).
- `echo pw | base64` includes the newline; use `printf %s`/`echo -n` (and see C07 for `--from-file`
  newlines).
- base64 is encoding, not encryption: anyone who can `get secrets` reads them. Protect with RBAC, encryption
  at rest, and keep plain Secrets out of Git (SOPS, Sealed Secrets, ESO: the Y track).
