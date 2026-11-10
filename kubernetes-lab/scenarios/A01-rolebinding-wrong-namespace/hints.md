## Hint 1
`kubectl auth can-i list pods -n monitor --as=system:serviceaccount:monitor:scraper`;
`kubectl get rolebindings -A | grep scraper`.

## Hint 2
A RoleBinding grants a Role's permissions **in the namespace of the RoleBinding** - whatever the subject's
namespace.

## Hint 3
Put the Role and the RoleBinding into `monitor` (metadata.namespace), apply, and delete the ones in
`default`.
