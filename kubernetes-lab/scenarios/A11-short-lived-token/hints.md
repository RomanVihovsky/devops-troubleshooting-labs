## Hint 1
Decode the token's payload: `cut -d. -f2 workspace/A11/ci-token.txt | base64 -d 2>/dev/null; echo` (add `=`
padding if needed). Look at `exp` and at `kubernetes.io` - what was it bound to?

## Hint 2
Tokens from the TokenRequest API (`kubectl create token`, projected volumes) expire and can be **bound** to an
object (a pod): when that object is gone, the token is rejected. A legacy-style token lives in a Secret of type
`kubernetes.io/service-account-token` and has no expiry.

## Hint 3
Create a Secret `ci-bot-token` in `ci2` with `type: kubernetes.io/service-account-token` and the annotation
`kubernetes.io/service-account.name: ci-bot` (no data - the token controller fills it in), then
`kubectl -n ci2 get secret ci-bot-token -o jsonpath='{.data.token}' | base64 -d > workspace/A11/ci-token.txt`.
