advertised() { [ "$(kx get node k8s-w3 -o jsonpath='{.status.capacity.example\.com/gpu}/{.status.allocatable.example\.com/gpu}')" = 2/2 ]; }
on_w3() { [ "$(kx -n ml get pods -l app=trainer --field-selector=status.phase=Running -o jsonpath='{.items[*].spec.nodeName}')" = k8s-w3 ]; }
still_requests() { [ "$(kx -n ml get deploy trainer -o jsonpath='{.spec.template.spec.containers[0].resources.requests.example\.com/gpu}')" = 1 ]; }
check_eventually 60 "k8s-w3 advertises example.com/gpu: 2" advertised
check_eventually 120 "trainer runs on k8s-w3" on_w3
check "trainer still requests example.com/gpu: 1" still_requests
verdict
