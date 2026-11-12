# demo: the rotated API token is rejected (401)
**INC-2260** · P2 · Reporter: API consumer team

Security rotated the demo API token yesterday (dev-bob sealed it, merged it to `envs/demo`, and tested it on
`demo-staging` first). Clients switched to the new token (`workspace/Y01/new-token.txt`) and get **401**; the
**old** token still works on demo - it must not. Fix it in Git.

**Test**: on demo, the new token gets 200 and the old one 401; the SealedSecret `demo/demo-auth` is
decrypted (Synced); demo is Synced + Healthy in Argo CD; the token is sealed in Git (no plain Secret).
