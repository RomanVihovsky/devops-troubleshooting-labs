# Every request takes exactly 5 seconds extra
**LNX-123** · P2 · Reporter: backend team

Since the network migration, every call from srv to `http://api.internal:8080/` takes
**~5 s**. Calling the IP directly (`curl http://10.77.0.20:8080/`) is instant. The API team
swears their service answers in 2 ms. It's *always* almost exactly 5 seconds.

**Test**: on srv, `curl http://api.internal:8080/` completes in under 1 s (3 times in a row).
