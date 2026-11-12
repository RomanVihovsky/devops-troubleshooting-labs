# storefront can't reach the inventory API since the namespace split
**INC-2605** · P2 · Reporter: storefront team

We split the monolith namespace: `storefront` (web) and `inventory-api` (the API, Service `api`). Since
then the storefront's `/upstream` fails with a name resolution error. The manifest is
`workspace/N05/storefront.yaml`. The API team's namespace stays as it is.

**Test**: the storefront reaches the API (`/upstream` → 200 inside the cluster); nothing changed in
`inventory-api`.
