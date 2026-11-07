# It's always DNS
**LNX-121** · P1 · Reporter: backend team

From `srv`, the app can't talk to the internal API: `curl http://api.internal:8080/`
fails. But `dig api.internal` returns the correct address (10.77.0.20) and
`curl http://10.77.0.20:8080/` works. The network team says DNS is fine.

**Test**: on srv, `curl http://api.internal:8080/` returns `api OK`, and
`getent hosts api.internal` resolves to 10.77.0.20.
