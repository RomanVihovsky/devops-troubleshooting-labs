## Hint 1
Decode what the pod gets: `kubectl -n cart get secret cart-redis -o jsonpath='{.data.password}' | base64 -d`.
Compare it with `redis-auth`'s.

## Hint 2
`data:` values are base64 **by definition** - the API decodes them once. The file put an already
base64-encoded string under `data:`, so the decoded value is still base64.

## Hint 3
Use `stringData:` with the plain value (or `data:` with a single encoding), apply, then
`kubectl -n cart rollout restart deploy/cart` - env vars from a Secret are read at start.
