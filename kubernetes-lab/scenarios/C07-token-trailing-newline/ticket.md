# ledger can't call the partner gateway - "works on my machine"
**INC-2623** · P2 · Reporter: team ledger

`ledger` calls `partner-gw` with a bearer token and has been NotReady since we moved the token into a Secret.
The token is right: from a laptop `curl -H "Authorization: Bearer $(cat token.txt)" ...` works with exactly
the file we put in the Secret (`workspace/C07/token.txt`):

    kubectl -n ledger create secret generic partner-token --from-file=token=token.txt

ledger's log says *Invalid return character or leading space in header: Authorization*. The token and
`partner-gw` must not change.

**Test**: `ledger` is Ready (its upstream check passes); Secret `partner-token` holds exactly the token
`partner-gw` expects; `partner-gw` still rejects calls without the token (401); ledger reads the token from the
Secret, not from a literal in its manifest.
