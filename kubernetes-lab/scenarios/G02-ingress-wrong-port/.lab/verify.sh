ok200() { [ "$(http_out http://192.168.56.200/ catalog.lab)" = 200 ]; }
port8080() { kx -n catalog2 get svc catalog -o jsonpath='{.spec.ports[*].port}' | grep -qw 8080; }
check_eventually 60 "catalog.lab answers 200 through the Ingress" ok200
check "Service catalog still exposes 8080" port8080
verdict
