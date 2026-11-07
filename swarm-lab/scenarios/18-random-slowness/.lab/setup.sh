deploy_stack
retry 60 svc_converged app_web
retry 60 svc_converged app_redis
retry 60 all_nodes_http / 'hits=' 2
# delay + loss only for VXLAN packets leaving worker1; ICMP/ssh untouched
inject worker1 '
  tc qdisc add dev eth0 root handle 1: prio &&
  tc qdisc add dev eth0 parent 1:3 handle 30: netem delay 400ms 150ms loss 5% &&
  tc filter add dev eth0 protocol ip parent 1:0 prio 3 u32 match ip dport 4789 0xffff flowid 1:3' \
  'tc qdisc del dev eth0 root'
