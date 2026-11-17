nxi k8s-w2 >/dev/null <<'__X__'
set -eu
f=/etc/containerd/config.toml
sed -i "s|sandbox = 'registry.internal.corp/k8s/pause:\([^']*\)'.*|sandbox = 'registry.k8s.io/pause:\1'|" "$f"
systemctl restart containerd
__X__
retry 150 deploy_ready shipping shipping-api 2 || true
