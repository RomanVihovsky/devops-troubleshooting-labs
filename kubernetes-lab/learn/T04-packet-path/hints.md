## Hint 1
`kubectl -n t04 get pods -o wide` shows IP and NODE. On a node (`./lab node w1`, `sudo -i`):
`iptables -t nat -S KUBE-SERVICES | grep t04/web` → `-j KUBE-SVC-XXXX`; then `iptables -t nat -S
KUBE-SVC-XXXX` → `-j KUBE-SEP-YYYY`; `iptables -t nat -S KUBE-SEP-YYYY` → `--to-destination ip:port`.

## Hint 2
`ip route get 10.244.x.y` → `via 10.244.a.b dev vxlan.calico`: each node owns /26 blocks; the gateway is
the other node's VXLAN tunnel address. `ip -d link show vxlan.calico` prints `mtu` and `dstport`.

## Hint 3
`bridge fdb show dev vxlan.calico` maps the remote VTEP MAC to `dst <node IP>` - the outer IP header of
the VXLAN packet. MTU 1450 = 1500 - 50 bytes of VXLAN overhead (outer IP 20 + UDP 8 + VXLAN 8 + inner
Ethernet 14).
