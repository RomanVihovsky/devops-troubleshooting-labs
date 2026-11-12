kx patch node k8s-w3 --subresource=status --type=json -p '[{"op":"add","path":"/status/capacity/example.com~1gpu","value":"2"}]' >/dev/null
r() { [ "$(kx -n ml get pods -l app=trainer --field-selector=status.phase=Running --no-headers | wc -l)" = 1 ]; }
retry 120 r || true
