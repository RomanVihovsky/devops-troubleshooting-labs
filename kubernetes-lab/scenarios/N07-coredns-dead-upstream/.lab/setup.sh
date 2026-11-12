# N07: a dead upstream - cluster.local still answers from the kubernetes plugin
[ ! -f "$STATE_DIR/offline" ] || die "N07 needs internet access (./lab vm offline off)"
cf=$(kx -n kube-system get configmap coredns -o jsonpath='{.data.Corefile}' | sed 's|forward \. /etc/resolv.conf|forward . 10.255.255.1|')
kx -n kube-system patch configmap coredns --type merge -p "$(jq -n --arg c "$cf" '{data: {Corefile: $c}}')" >/dev/null
kx -n kube-system rollout restart deploy/coredns >/dev/null
kx -n kube-system rollout status deploy/coredns --timeout=180s >/dev/null
