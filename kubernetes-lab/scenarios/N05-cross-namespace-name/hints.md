## Hint 1
`kubectl -n storefront exec deploy/storefront -- cat /etc/resolv.conf` - which search domains does a
pod get?

## Hint 2
A short name like `api` resolves in the pod's **own** namespace (`api.storefront.svc.cluster.local`).

## Hint 3
`UPSTREAM_URL: http://api.inventory-api/items` (or the FQDN), apply.
