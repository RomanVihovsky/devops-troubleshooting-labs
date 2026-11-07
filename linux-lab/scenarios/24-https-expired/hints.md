## Hint 1
Check what the server actually **serves**, not what's on disk:
`openssl s_client -connect srv.lab:443 -servername srv.lab </dev/null 2>/dev/null | openssl x509 -noout -dates -serial`
## Hint 2
A running nginx keeps the certificate it loaded at start/reload. Did anyone reload it?
What happens if you do? `sudo nginx -t`.
## Hint 3
"key values mismatch": the renewal created a **new private key** under a different name.
Compare `openssl x509 -noout -pubkey -in srv.crt` with `openssl pkey -pubout -in <key>` and
point `ssl_certificate_key` at the right one. Then `nginx -t && systemctl reload nginx`.
