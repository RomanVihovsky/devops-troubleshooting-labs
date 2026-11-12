## Hint 1
`kubectl describe clustersecretstore openbao`. Then compare the CA in the ConfigMap with the one OpenBao's
certificate chains to: `kubectl -n external-secrets get cm lab-ca -o jsonpath='{.data.ca\.crt}' | openssl x509
-noout -subject -fingerprint -sha256` vs `openssl x509 -noout -subject -fingerprint -sha256 -in $BAO_CACERT`.

## Hint 2
Same subject, different key: it's an older CA with the same name. `openssl s_client -connect 192.168.56.20:8200
-CAfile <file> </dev/null` tells you which one verifies OpenBao's certificate.

## Hint 3
`kubectl -n external-secrets create configmap lab-ca --from-file=ca.crt=$BAO_CACERT --dry-run=client -o yaml |
kubectl apply -f -`, then `kubectl -n shop annotate externalsecret shop-secrets force-sync=$(date +%s) --overwrite`.
