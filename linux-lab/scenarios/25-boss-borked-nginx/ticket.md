# Boss fight: the shop is down after a "tuning session"
**LNX-125** · P0 · Reporter: CTO

Someone spent Friday evening "tuning" nginx on srv. Monday morning: the shop is down,
nginx won't even start. Get it **fully** working - more than one thing is wrong.

**Test**: nginx runs, `curl localhost/` shows the shop, `curl localhost/assets/app.css`
returns 200, and 50 concurrent requests all succeed (each within 2 s).
