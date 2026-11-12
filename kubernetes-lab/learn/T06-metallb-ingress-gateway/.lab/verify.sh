source "$SCN/.lab/facts.sh"
lb_ip() { [ "$(kx -n t06 get svc hello-lb -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)" = 192.168.56.210 ]; }
lb_200() { [ "$(http_out http://192.168.56.210/)" = 200 ]; }
ing_200() { [ "$(http_out http://192.168.56.200/ t06.lab)" = 200 ]; }
route_accepted() { [ "$(kx -n t06 get httproute hello -o jsonpath='{.status.parents[0].conditions[?(@.type=="Accepted")].status}' 2>/dev/null)" = True ]; }
gw_200() { [ "$(http_out http://192.168.56.200/ t06-gw.lab)" = 200 ]; }
check_eventually 60 "hello-lb got 192.168.56.210 from MetalLB" lb_ip
check_eventually 60 "http://192.168.56.210/ -> 200 from the desktop" lb_200
check_eventually 60 "Ingress: Host t06.lab via 192.168.56.200 -> 200" ing_200
check_eventually 60 "HTTPRoute hello Accepted by traefik-gateway" route_accepted
check_eventually 60 "HTTPRoute: Host t06-gw.lab via 192.168.56.200 -> 200" gw_200
check "answers: the node announcing 192.168.56.210" answered l2_node "$(f_l2_node)"
verdict
