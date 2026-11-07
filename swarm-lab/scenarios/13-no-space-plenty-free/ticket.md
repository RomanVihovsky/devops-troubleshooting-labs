# "No space left on device" with 99% free
**SWARM-113** · Priority P1 · Reporter: on-call

Logins fail. `/health` says
`cannot create session: [Errno 28] No space left on device: '/sessions/...'`.
But `df -h /sessions` inside the container shows the 256 MB volume **1% used**.
Restarting the task does not help.

Sessions are restored from a snapshot at startup (`SESSION_SNAPSHOT`) - that is a
business requirement and must stay.

**Done when**
- `/health` returns 200 via every node
- ...and still does after a forced redeploy (`./lab verify` does one)
- `SESSION_SNAPSHOT` is still 5000
