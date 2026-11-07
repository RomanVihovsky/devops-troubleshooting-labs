# Solution - renewed cert on disk, old cert in memory, mismatched key

**Root cause**: two layers.
1. nginx loads certificates at start/reload. The renewal wrote a new `srv.crt` but never
   reloaded nginx, so it still **serves the expired one from memory**.
2. Reloading wouldn't have helped: the renewal also generated a **new private key**
   (`srv-2026.key`) while nginx still points at `srv.key`. `nginx -t` fails with
   `key values mismatch`, and a failed reload keeps the old config (and old cert) running.

**Diagnose**
```
openssl s_client -connect srv.lab:443 -servername srv.lab </dev/null 2>/dev/null \
  | openssl x509 -noout -dates -serial        # what is SERVED (expired)
openssl x509 -in /etc/ssl/lab/srv.crt -noout -dates -serial   # what is on DISK (valid)
sudo nginx -t                                  # key values mismatch
openssl x509 -noout -pubkey -in srv.crt | sha256sum
openssl pkey -pubout -in srv-2026.key | sha256sum             # match -> right key
```

**Fix**: `ssl_certificate_key /etc/ssl/lab/srv-2026.key;` then `nginx -t && systemctl reload nginx`.
Make the renewal hook run `nginx -t && systemctl reload nginx` (certbot `--deploy-hook`).

**Interview notes**: other TLS breakers: missing intermediate chain (`fullchain.pem`),
wrong SNI/vhost, hostname not in SAN, client clock skew, old TLS versions/ciphers
disabled, CA not in the client's trust store (`update-ca-certificates`).
