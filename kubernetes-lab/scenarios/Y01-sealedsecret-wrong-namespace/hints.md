## Hint 1
`kubectl -n demo get sealedsecret demo-auth -o yaml` - look at `status.conditions` (and the
sealed-secrets controller's logs in `kube-system`). Why does staging decrypt the same thing?

## Hint 2
A strict-scope SealedSecret is bound to **namespace + name**: it was sealed for `demo-staging`. Decryption
fails in `demo`, the controller leaves the existing Secret alone - the old token keeps working.

## Hint 3
`tr -d '\n' < workspace/Y01/new-token.txt | kubeseal --raw --scope strict --namespace demo --name demo-auth
--from-file=/dev/stdin` → put the result into `secrets.sealedSecret.encryptedData.auth-token` in
`envs/demo/values.yaml`, push, refresh. The chart's checksum annotation rolls the pods.
