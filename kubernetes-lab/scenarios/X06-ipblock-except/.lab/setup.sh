# X06: the egress ipBlock's except covers .16-.31, the payment API (.20) included; the rest of the /24 is wide open
kns payx
ka -f egress.yaml
! tcp_ok_as payx app=client 192.168.56.20:8080 || die "the payment API is reachable"
