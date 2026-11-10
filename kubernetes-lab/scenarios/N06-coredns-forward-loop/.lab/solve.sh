cf=$(kx -n kube-system get configmap coredns -o jsonpath='{.data.Corefile}' | sed 's|forward \. 127.0.0.1|forward . /etc/resolv.conf|')
kx -n kube-system patch configmap coredns --type merge -p "$(jq -n --arg c "$cf" '{data: {Corefile: $c}}')" >/dev/null
kx -n kube-system rollout restart deploy/coredns >/dev/null
kx -n kube-system rollout status deploy/coredns --timeout=180s >/dev/null
