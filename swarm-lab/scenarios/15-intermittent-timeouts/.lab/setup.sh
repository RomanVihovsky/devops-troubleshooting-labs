deploy_stack
retry 60 svc_converged app_web
retry 60 svc_converged app_redis
retry 60 all_nodes_http / 'hits=' 2
# the "CIS hardening baseline" applied during maintenance
inject worker2 '
  iptables -N SEC-BASELINE
  iptables -A SEC-BASELINE -m conntrack --ctstate ESTABLISHED,RELATED -j RETURN
  iptables -A SEC-BASELINE -i lo -j RETURN
  iptables -A SEC-BASELINE -p icmp -j RETURN
  iptables -A SEC-BASELINE -p tcp -m multiport --dports 22,2377,7946 -j RETURN
  iptables -A SEC-BASELINE -p udp --dport 7946 -j RETURN
  iptables -A SEC-BASELINE -p udp --dport 1024:65535 -j DROP
  iptables -I INPUT 1 -j SEC-BASELINE' \
  'iptables -D INPUT -j SEC-BASELINE; iptables -F SEC-BASELINE; iptables -X SEC-BASELINE'
