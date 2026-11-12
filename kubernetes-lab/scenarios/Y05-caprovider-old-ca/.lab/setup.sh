# Y05: external-secrets/lab-ca (the ClusterSecretStore's caProvider) now holds an older CA with the same subject
d=$(mktemp -d)
openssl ecparam -name prime256v1 -genkey -noout -out "$d/old.key"
openssl req -x509 -new -key "$d/old.key" -sha256 -days 3650 -subj "/CN=kubernetes-lab CA" \
  -addext "basicConstraints=critical,CA:TRUE" -addext "keyUsage=critical,keyCertSign,cRLSign" -out "$d/old.crt"
kx -n external-secrets create configmap lab-ca --from-file=ca.crt="$d/old.crt" --dry-run=client -o yaml | kx apply -f - >/dev/null
rm -rf "$d"
# ESO re-validates stores on its own schedule - nudge the store and shop's ExternalSecret now
kx annotate clustersecretstore openbao force-sync="$(date +%s)" --overwrite >/dev/null
kx -n shop annotate externalsecret shop-secrets force-sync="$(date +%s)" --overwrite >/dev/null
failing() { kx -n shop get externalsecret shop-secrets -o json | jq -e '[.status.conditions[]? | select(.type == "Ready" and .status == "False")] | length > 0' >/dev/null; }
retry 180 failing || die "shop-secrets still syncs"
