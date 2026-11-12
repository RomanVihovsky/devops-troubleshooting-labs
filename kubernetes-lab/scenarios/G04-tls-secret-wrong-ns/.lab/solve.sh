kx -n secure create secret tls secure-tls --cert=secure.crt --key=secure.key --dry-run=client -o yaml | kx apply -f - >/dev/null
kx -n default delete secret secure-tls --ignore-not-found >/dev/null
r() { [ "$(https_out secure.lab)" = 200 ]; }
retry 60 r || true
