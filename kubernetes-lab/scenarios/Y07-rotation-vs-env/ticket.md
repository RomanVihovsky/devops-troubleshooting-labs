# notifier gets 401 from upstream since the token rotation
**INC-2371** · P2 · Reporter: security

We rotated `secret/notify/api` (key `token`) in OpenBao an hour ago, as the quarterly policy requires. ESO
synced it into Secret `notify/api-token` within a minute, and `upstream` (which reads the token from a mounted
file) accepts only the new one. `notifier` still sends the old token and every call fails with 401
(`notifier`'s `/upstream` endpoint shows it). A restart would fix it today - but rotations happen every quarter,
and the next one must not need anybody. The manifests are in `workspace/Y07/`.

**Test**: `notifier`'s `/upstream` answers 200; then the test rotates the token **again** in OpenBao and
`notifier` keeps working without anyone touching it (within ~3 minutes); the token still comes from the Secret
`api-token` (no literal in the manifest).
