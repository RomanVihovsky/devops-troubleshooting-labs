## Hint 1
`kubectl get crd widgets.example.lab -o yaml` - read `spec.versions[*].served/storage` and `status.storedVersions`.
`kubectl get --raw /apis/example.lab/v1/namespaces/factory/widgets` vs `.../v2/...`.

## Hint 2
A version with `served: false` is gone from the API, even though objects written as v1 are still in etcd (as
v1!). `storedVersions` remembers every version that was ever the storage version - the API server never rewrites
objects by itself.

## Hint 3
1. Set `served: true` on v1 (keep `storage: true` on v2) and apply. 2. Rewrite every widget so it's stored as v2:
`kubectl -n factory get widgets.v2.example.lab -o json | kubectl replace -f -`. 3. Then drop v1 from the
status: `kubectl patch crd widgets.example.lab --subresource=status --type=merge -p '{"status":{"storedVersions":["v2"]}}'`.
