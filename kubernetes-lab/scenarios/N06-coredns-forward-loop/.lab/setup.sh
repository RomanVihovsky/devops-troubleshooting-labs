# N06: forward to 127.0.0.1 = to itself - the loop plugin aborts CoreDNS
cf=$(kx -n kube-system get configmap coredns -o jsonpath='{.data.Corefile}' | sed 's|forward \. /etc/resolv.conf|forward . 127.0.0.1|')
grep -q 'forward . 127.0.0.1' <<<"$cf" || die "Corefile has no forward to /etc/resolv.conf"
kx -n kube-system patch configmap coredns --type merge -p "$(jq -n --arg c "$cf" '{data: {Corefile: $c}}')" >/dev/null
kx -n kube-system rollout restart deploy/coredns >/dev/null
retry 180 crashlooping kube-system k8s-app=kube-dns || die "CoreDNS did not crash"
