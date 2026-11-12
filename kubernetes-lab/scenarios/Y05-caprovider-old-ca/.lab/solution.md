# Y05 - a caProvider with the wrong CA (same name, different key)

**Root cause**: the ClusterSecretStore trusts the CA in ConfigMap `external-secrets/lab-ca` (`caProvider`). The
"cleanup" put in an older CA certificate. It has the **same subject** (`CN=kubernetes-lab CA`) but a different
key, so OpenBao's server certificate doesn't chain to it. Every TLS handshake from ESO to OpenBao failed, the
store went NotReady, and no ExternalSecret could refresh. Existing Secrets stayed, so the apps kept running
on their last values. That is why it looked harmless.

**Diagnosis**
```
kubectl describe clustersecretstore openbao     # x509: certificate signed by unknown authority
kubectl -n external-secrets get cm lab-ca -o jsonpath='{.data.ca\.crt}' | openssl x509 -noout -subject -fingerprint -sha256
openssl x509 -noout -subject -fingerprint -sha256 -in "$BAO_CACERT"   # same subject, different fingerprint
openssl s_client -connect 192.168.56.20:8200 -CAfile "$BAO_CACERT" </dev/null 2>/dev/null | grep 'Verify return code'
```

**Fix**: put the current CA back and force a refresh:
```
kubectl -n external-secrets create configmap lab-ca --from-file=ca.crt="$BAO_CACERT" --dry-run=client -o yaml | kubectl apply -f -
kubectl -n shop annotate externalsecret shop-secrets force-sync=$(date +%s) --overwrite
```

**Interview notes**
- Compare certificates by **fingerprint** (or subject key identifier), never by subject name. CA rotations
  often keep the subject.
- During a CA rotation, the trust bundle holds old + new until every server cert is re-issued. Then the old
  one is removed. trust-manager (cert-manager project) distributes such bundles into namespaces.
- `insecure`/skip-verify "fixes" make an attacker on the path a secret reader. ESO's Vault provider
  deliberately has no such switch.
- Failing secret refreshes are silent until a rotation happens. Alert on ESO's
  `externalsecret_status_condition{condition="Ready",status="False"}` and on store conditions.
