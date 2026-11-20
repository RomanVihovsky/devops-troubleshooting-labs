# L08: tc on w1: a prio qdisc + u32 filter sends traffic to the API LB (192.168.56.20:6443) into netem loss 90 %
nxi k8s-w1 >/dev/null <<'__X__'
set -eu
dev=$(ip -o route get 192.168.56.20 | awk '{ for (i = 1; i <= NF; i++) if ($i == "dev") print $(i + 1) }')
tc qdisc replace dev "$dev" root handle 1: prio bands 4 priomap 1 2 2 2 1 2 0 0 1 1 1 1 1 1 1 1
tc qdisc add dev "$dev" parent 1:4 handle 40: netem loss 90%
tc filter add dev "$dev" parent 1: protocol ip prio 1 u32 match ip dst 192.168.56.20/32 match ip dport 6443 0xffff flowid 1:4
__X__
not_ready() { [ "$(kx get node k8s-w1 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')" != True ]; }
retry 240 not_ready || die "k8s-w1 never went NotReady"
