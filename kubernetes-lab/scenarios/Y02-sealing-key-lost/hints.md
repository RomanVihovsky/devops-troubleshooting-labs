## Hint 1
`kubectl get sealedsecrets -A`, `kubectl -n demo describe sealedsecret demo-auth`, and
`kubectl -n kube-system logs deploy/sealed-secrets-controller | tail`. Which key decrypts a SealedSecret?

## Hint 2
SealedSecrets are encrypted with the controller's public key; only the matching private key (Secrets in
`kube-system` labelled `sealedsecrets.bitnami.com/sealed-secrets-key`) can open them. A restart without any key makes
the controller generate a **new** pair - useless for the existing ciphertexts.

## Hint 3
`kubectl apply -f .state/sealed-secrets-key.yaml` (restores the old key Secret), then restart the controller
(`kubectl -n kube-system rollout restart deploy/sealed-secrets-controller`) - it loads every key it finds and
decrypts again. Keep the new key too, or remove it - both work.
