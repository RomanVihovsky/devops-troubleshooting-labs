# C07 - `--from-file` keeps the trailing newline

**Root cause**: `kubectl create secret --from-file` stores the file byte for byte. `token.txt` ends with a newline
(every editor adds one), so the Secret's value is `pgw_...\n`. labapp - like most HTTP clients - refuses to put
a newline into a header ("Invalid return character ... Authorization"); some servers would instead just answer
401. On the laptop `$(cat token.txt)` strips trailing newlines, so the same file "worked".

**Diagnosis**
```
kubectl -n ledger logs deploy/ledger | tail
kubectl -n ledger get secret partner-token -o jsonpath='{.data.token}' | base64 -d | od -c | tail -2   # ... \n
kubectl -n ledger get secret partner-token -o jsonpath='{.data.token}' | base64 -d | wc -c              # 37, not 36
```

**Fix**: store the value without the newline and let the mounted file refresh (about a minute; labapp re-reads
`*_FILE` per call - an env var would need a restart):
```
kubectl -n ledger create secret generic partner-token --from-literal=token="$(cat token.txt)" \
  --dry-run=client -o yaml | kubectl apply -f -
```

**Interview notes**
- `echo -n`, `printf %s`, `--from-literal`, or `stringData:` in YAML (a `|-` block, not `|`) avoid the newline.
- The same bug hits passwords (`WRONGPASS`), API keys in env vars, and base64 of `echo` output (`echo x | base64`
  encodes the newline too - C03 is its cousin).
- Robust apps `strip()` secrets read from files; Kubernetes never does.
