# G04: the TLS Secret was created in "default" (the current namespace), the Ingress is in "secure"
kns secure
issue_cert g04 DNS:secure.lab
cp "$CA_DIR/g04.crt" secure.crt; cp "$CA_DIR/g04.key" secure.key
kx -n default create secret tls secure-tls --cert=secure.crt --key=secure.key --dry-run=client -o yaml | ka -f -
ka -f secure.yaml
wait_rollout secure deploy/secure
[ "$(https_out secure.lab)" = 000 ] || die "secure.lab already serves a valid cert"
