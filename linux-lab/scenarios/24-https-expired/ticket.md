# HTTPS broke - but the certificate was renewed
**LNX-124** · P1 · Reporter: on-call

Clients get `SSL certificate problem: certificate has expired` from `https://srv.lab/`
(try: `./lab sh client`, then `curl https://srv.lab/`). The renewal job ran last night
and `openssl x509 -in /etc/ssl/lab/srv.crt -noout -dates` on srv shows a cert valid
until 2027. "It must be a client cache."

**Test**: from client, `curl https://srv.lab/` succeeds with normal certificate
verification (no `-k`), and `nginx -t` passes on srv.
