# "No space left on device" - but df says 99% free
**LNX-108** · P1 · Reporter: on-call

Logins fail: `curl localhost:8082/login` returns 500 with
`[Errno 28] No space left on device`. Yet `df -h` shows the sessions volume
(`/var/lib/app/sessions`) almost empty.

Sessions modified in the **last 24 hours** belong to logged-in users and must **not** be deleted.

**Test**: `/login` returns 200, inode usage of the sessions volume is below 50%, and all
recent (< 24 h) sessions still exist.
