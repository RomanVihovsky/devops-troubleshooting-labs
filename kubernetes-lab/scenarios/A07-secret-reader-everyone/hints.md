## Hint 1
`kubectl auth can-i list secrets -A --as bob`, then find the grant: `kubectl get clusterrolebindings -o wide | grep
-i secret`.

## Hint 2
`system:authenticated` is a group every authenticated identity belongs to (users **and** ServiceAccounts). A
ClusterRoleBinding to it gives the ClusterRole to everyone.

## Hint 3
Bind the ClusterRole to the ServiceAccount only:
`kubectl patch clusterrolebinding secret-reader --type json -p '[{"op":"replace","path":"/subjects","value":[{"kind":"ServiceAccount","name":"backup-agent","namespace":"backup"}]}]'`.
