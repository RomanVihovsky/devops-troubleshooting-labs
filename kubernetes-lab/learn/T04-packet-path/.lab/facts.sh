# T04: the live truth behind the answers (sourced by verify and solve)
f_web_pod_ip() { kx -n t04 get pods -l app=web -o jsonpath='{.items[0].status.podIP}'; }
f_web_node() { kx -n t04 get pods -l app=web -o jsonpath='{.items[0].spec.nodeName}'; }
f_svc_chain() { nx k8s-w1 "iptables -t nat -S KUBE-SERVICES | grep 't04/web' | grep -o 'KUBE-SVC-[A-Z0-9]*' | head -1" </dev/null; }
f_dnat_target() { echo "$(f_web_pod_ip):8080"; }
f_vxlan_mtu() { nx k8s-w1 'cat /sys/class/net/vxlan.calico/mtu' </dev/null; }
f_vxlan_port() { nx k8s-w1 "ip -d link show vxlan.calico | grep -o 'dstport [0-9]*' | awk '{ print \$2 }'" </dev/null; }
f_vxlan_peer() { node_ip "$(f_web_node)"; }
