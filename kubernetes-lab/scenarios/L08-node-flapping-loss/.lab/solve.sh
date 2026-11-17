nxi k8s-w1 >/dev/null <<'__X__'
dev=$(ip -o route get 192.168.56.20 | awk '{ for (i = 1; i <= NF; i++) if ($i == "dev") print $(i + 1) }')
tc qdisc del dev "$dev" root 2>/dev/null || true
__X__
ready() { [ "$(kx get node k8s-w1 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')" = True ]; }
retry 120 ready || true
