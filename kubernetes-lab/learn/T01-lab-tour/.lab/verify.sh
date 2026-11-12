source "$SCN/.lab/facts.sh"
hello_ready() { [ "$(kx -n t01 get deploy hello -o jsonpath='{.status.readyReplicas}' 2>/dev/null)" = 2 ]; }
hello_image() { kx -n t01 get deploy hello -o jsonpath='{.spec.template.spec.containers[*].image}' | grep -q 'lab/labapp:1.4$'; }
check "containerd version on k8s-w2" answered containerd_version_w2 "$(f_containerd_w2)"
check "zone of k8s-w3" answered zone_w3 "$(f_zone_w3)"
check "Argo CD UI LoadBalancer IP" answered argocd_ip "$(f_argocd_ip)"
check "haproxy's API backend (ip:port)" answered api_backend "$(f_api_backend)"
check "default StorageClass" answered default_storageclass "$(f_default_sc)"
check "reset level of L01" answered l01_reset "$(f_l01_reset)"
check_eventually 90 "t01/hello: 2 ready replicas" hello_ready
check "t01/hello runs registry.lab:5000/lab/labapp:1.4" hello_image
check_eventually 60 "http://hello.t01/ answers 200 inside the cluster" http_ok t01 http://hello.t01/
verdict
